import { defineStore } from 'pinia';
import camelcaseKeys from 'camelcase-keys';
import CoopModulesAPI from 'dashboard/api/coop/modules';

// Pundit's `render_unauthorized` (see request_exception_handler.rb) returns a
// plain `{ error: message }` body with no `error_code`, so permission
// failures can only be told apart from other failures (500, network) by
// status code. See coopProducers.js for the same helper.
const isPermissionError = error => [401, 403].includes(error?.response?.status);

const buildToggleError = error => {
  const message =
    error?.response?.data?.error || error?.message || 'Unknown error';
  const richError = new Error(message);
  richError.isPermissionError = isPermissionError(error);
  return richError;
};

// CoopFlow modules are keyed by `key` (e.g. "producers"), not `id` --
// createStore's generic CRUD factory assumes an `id`-keyed record list, so
// this store is defined directly instead of going through it.
export const useCoopModulesStore = defineStore('coopModules', {
  state: () => ({
    modules: [],
    uiFlags: {
      fetchingList: false,
      togglingKeys: [],
    },
    // null | 'permission' | 'server' -- read-only failure state for `fetch`,
    // consumed by the modules settings screen. The sidebar also calls
    // `fetch()` (fire-and-forget, see below) but never reads this.
    fetchError: null,

    // In-flight request coordination. Kept in `state()` (not module-scoped
    // closures) so every store instance -- and `$reset()` -- starts clean;
    // that also makes the concurrency behavior below deterministic to test.
    // Nothing in the UI ever reads these directly.
    //
    // Pinia wraps state in Vue's `reactive()`, but `reactive()` only
    // proxies the object/array/collection types Vue recognizes --
    // `toRawType(Promise.resolve())` is `'Promise'`, which is not one of
    // them (Vue's internal `targetTypeMap` has no entry for it, so it
    // falls through to `TargetType.INVALID`). So the raw Promises kept
    // below are never wrapped, and their identity/resolution is
    // unaffected by living in Pinia state. Verified when this comment was
    // written -- no need to re-litigate it.
    //
    // `fetchPromise`: Sidebar.vue and the modules settings screen both call
    // `fetch()` independently on mount -- reuse the in-flight request
    // instead of racing two GETs against the shared `fetchingList` flag.
    // Because the GET itself is gated behind `mutationQueue` (see below)
    // rather than issued immediately, the shared promise resolves with
    // whatever the server returned once this fetch's turn in the queue
    // came up. Caveat: a caller deduped onto an already-pending fetch can
    // still receive a resolved VALUE that lags the live `this.modules`
    // state -- e.g. fetch A queued, a toggle queued behind it, then fetch
    // B deduped onto A resolves with A's pre-toggle snapshot after the
    // toggle has already been applied to the store. Queue ordering keeps
    // `this.modules` itself correct; callers must read the reactive
    // getters, never trust the resolved value.
    fetchPromise: null,
    // `mutationQueue`: the tail of a TOTAL-ORDER chain over every read and
    // write to `this.modules`. Both `toggle()`'s PATCH (via `issueToggle`)
    // and `fetch()`'s GET (via `applyFetchResponse`) are not merely
    // *applied* in queue order -- they are *issued* only once whatever is
    // currently queued has settled, so requests hit the wire, and
    // therefore resolve, strictly in the order they were *called*, never
    // in network-response order. That's what closes the fetch-vs-toggle
    // race in BOTH directions: a `fetch()` queued behind a `toggle()`
    // won't send its GET until the toggle's PATCH has landed (so it can't
    // later overwrite a fresher toggle result with a pre-toggle
    // snapshot), and a `toggle()` queued behind a `fetch()` won't send its
    // PATCH until the fetch's GET has landed. PATCH/GET responses are
    // FULL-LIST snapshots (the resolver can cascade one toggle to other
    // modules), so there's no per-row optimistic update to fall back on --
    // an out-of-order write would silently regress the whole list, not
    // just one row.
    //
    // Trade-off: this is head-of-line blocking by design -- one slow or
    // stalled request delays every read and write queued behind it. Axios
    // has no default timeout, so an unbounded stall could wedge the queue
    // forever; `CoopModulesAPI` sets an explicit request timeout (see
    // app/javascript/dashboard/api/coop/modules.js) specifically so a
    // stalled request eventually errors out instead, letting the queue
    // drain into the existing error paths (`fetchError` / toggle error
    // toast).
    mutationQueue: null,
  }),

  getters: {
    getModules: state => state.modules,
    getUIFlags: state => state.uiFlags,
    getFetchError: state => state.fetchError,
    isEnabled: state => key =>
      state.modules.find(coopModule => coopModule.key === key)?.enabled ??
      false,
    isToggling: state => key => state.uiFlags.togglingKeys.includes(key),
  },

  actions: {
    setUIFlag(data) {
      this.uiFlags = { ...this.uiFlags, ...data };
    },

    async fetch() {
      // A fetch is already in flight (see `fetchPromise` in `state()`) --
      // return it instead of issuing a second concurrent GET.
      if (this.fetchPromise) return this.fetchPromise;

      this.setUIFlag({ fetchingList: true });

      // The GET is issued from inside `applyFetchResponse`, only once
      // it's this call's turn in `mutationQueue` -- not immediately here.
      // Gating ISSUANCE (not just application) is what closes the
      // fetch-vs-toggle race in the fetch-after-toggle direction: if the
      // GET were sent up front, it could still be in flight when an
      // already-queued `toggle()`'s PATCH resolves first, and this GET's
      // pre-toggle snapshot would land -- and get applied -- after the
      // toggle's correct result, silently reverting it. See the
      // `mutationQueue` comment in `state()` for the full picture.
      const previous = this.mutationQueue
        ? this.mutationQueue.catch(() => {})
        : Promise.resolve();
      const request = previous.then(() => this.applyFetchResponse());
      this.mutationQueue = request;

      this.fetchPromise = request.finally(() => {
        this.setUIFlag({ fetchingList: false });
        this.fetchPromise = null;
      });

      return this.fetchPromise;
    },

    // Issues the GET and applies its response to `this.modules`, split out
    // of `fetch()` so it can be chained onto `mutationQueue` (see
    // `toggle()` / `issueToggle()` for the same pattern) without
    // duplicating the queue bookkeeping. The GET itself is not sent until
    // this function actually runs -- i.e. until it's this call's turn in
    // the queue. Never rejects -- the sidebar calls `fetch()`
    // fire-and-forget on mount, so a failure here must not throw; it only
    // ever updates `fetchError`.
    async applyFetchResponse() {
      try {
        const {
          data: { payload },
        } = await CoopModulesAPI.get();
        this.modules = camelcaseKeys(payload || [], { deep: true });
        this.fetchError = null;
        return this.modules;
      } catch (error) {
        // The sidebar calls `fetch()` fire-and-forget on mount -- a
        // modules fetch failure must never break the sidebar, so fail
        // closed (`modules` stays whatever it already was, i.e. `[]` on
        // first load) and just log instead of rejecting. `fetchError`
        // still records what happened for the settings screen, which
        // awaits this same call.
        this.fetchError = isPermissionError(error) ? 'permission' : 'server';
        // eslint-disable-next-line no-console
        console.error('[coopModules] Failed to fetch modules', error);
        return this.modules;
      }
    },

    // Writes the account-scope override for one module and re-renders the
    // full list from the response -- the resolver can cascade the change to
    // OTHER modules (e.g. disabling `producers` also resolves `requests` and
    // `agronomy` to false), so a per-row optimistic update would lie about
    // every row except the one just toggled. Returns what the caller asked
    // for vs. what the resolver actually settled on, so the UI can explain a
    // toggle that "didn't take" (kill switch, unmet dependency, etc.).
    //
    // Concurrent toggles on different rows -- and any `fetch()` queued
    // before or after them -- are serialized through `mutationQueue`: each
    // call's request (this toggle's PATCH via `issueToggle`, or a
    // `fetch()`'s GET via `applyFetchResponse`) is chained behind whatever
    // is currently queued/in-flight, and is not ISSUED until its turn
    // comes up -- so requests are issued, and therefore resolved, strictly
    // in the order the admin triggered them. That removes the
    // out-of-order-response window outright, in both directions (the
    // server re-evaluates the whole list on every write, so a response for
    // an older toggle -- or a stale `fetch()` GET -- landing after a newer
    // one would otherwise regress the list) instead of trying to detect it
    // after the fact with a sequence number. The per-row `togglingKeys`
    // pending flag is still set synchronously here, before queueing, so
    // the UI shows the row as pending immediately even while its PATCH
    // waits its turn.
    async toggle(key, enabled) {
      this.setUIFlag({ togglingKeys: [...this.uiFlags.togglingKeys, key] });

      const previous = this.mutationQueue
        ? this.mutationQueue.catch(() => {})
        : Promise.resolve();
      const request = previous.then(() => this.issueToggle(key, enabled));
      this.mutationQueue = request;

      try {
        return await request;
      } catch (error) {
        throw buildToggleError(error);
      } finally {
        this.setUIFlag({
          togglingKeys: this.uiFlags.togglingKeys.filter(
            togglingKey => togglingKey !== key
          ),
        });
      }
    },

    // The actual PATCH + list refresh, split out of `toggle()` so it can be
    // chained onto `mutationQueue` without duplicating the queue bookkeeping.
    async issueToggle(key, enabled) {
      const {
        data: { payload },
      } = await CoopModulesAPI.update(key, { enabled });
      const modules = camelcaseKeys(payload || [], { deep: true });
      this.modules = modules;

      const resolved =
        modules.find(coopModule => coopModule.key === key)?.enabled ?? false;
      return { requested: enabled, resolved };
    },
  },
});
