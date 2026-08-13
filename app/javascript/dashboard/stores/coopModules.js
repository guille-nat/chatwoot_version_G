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
      this.setUIFlag({ fetchingList: true });
      try {
        const {
          data: { payload },
        } = await CoopModulesAPI.get();
        this.modules = camelcaseKeys(payload || [], { deep: true });
        this.fetchError = null;
        return this.modules;
      } catch (error) {
        // The sidebar calls `fetch()` fire-and-forget on mount -- a modules
        // fetch failure must never break the sidebar, so fail closed
        // (`modules` stays whatever it already was, i.e. `[]` on first load)
        // and just log instead of rejecting. `fetchError` still records what
        // happened for the settings screen, which awaits this same call.
        this.fetchError = isPermissionError(error) ? 'permission' : 'server';
        // eslint-disable-next-line no-console
        console.error('[coopModules] Failed to fetch modules', error);
        return this.modules;
      } finally {
        this.setUIFlag({ fetchingList: false });
      }
    },

    // Writes the account-scope override for one module and re-renders the
    // full list from the response -- the resolver can cascade the change to
    // OTHER modules (e.g. disabling `producers` also resolves `requests` and
    // `agronomy` to false), so a per-row optimistic update would lie about
    // every row except the one just toggled. Returns what the caller asked
    // for vs. what the resolver actually settled on, so the UI can explain a
    // toggle that "didn't take" (kill switch, unmet dependency, etc.).
    async toggle(key, enabled) {
      this.setUIFlag({ togglingKeys: [...this.uiFlags.togglingKeys, key] });
      try {
        const {
          data: { payload },
        } = await CoopModulesAPI.update(key, { enabled });
        this.modules = camelcaseKeys(payload || [], { deep: true });
        const resolved =
          this.modules.find(coopModule => coopModule.key === key)?.enabled ??
          false;
        return { requested: enabled, resolved };
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
  },
});
