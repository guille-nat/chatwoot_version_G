import { setActivePinia, createPinia } from 'pinia';
import CoopModulesAPI from 'dashboard/api/coop/modules';
import { useCoopModulesStore } from '../coopModules';

vi.mock('dashboard/api/coop/modules', () => ({
  default: {
    get: vi.fn(),
    update: vi.fn(),
  },
}));

const createDeferred = () => {
  let resolve;
  let reject;
  const promise = new Promise((res, rej) => {
    resolve = res;
    reject = rej;
  });

  return { promise, resolve, reject };
};

// Lets already-queued microtasks (promise `.then()` chains) run before the
// test keeps going -- needed to observe the toggle queue's intermediate
// state (e.g. "only one PATCH issued so far") between two toggle() calls.
const flushMicrotasks = () =>
  new Promise(resolve => {
    setTimeout(resolve, 0);
  });

describe('coopModules store', () => {
  beforeEach(() => {
    setActivePinia(createPinia());
    vi.clearAllMocks();
  });

  describe('fetch', () => {
    it('dedupes concurrent fetch() calls onto a single GET', async () => {
      const request = createDeferred();
      CoopModulesAPI.get.mockReturnValueOnce(request.promise);

      const store = useCoopModulesStore();
      const first = store.fetch();
      const second = store.fetch();

      // The GET is issued from inside a microtask queued on `mutationQueue`
      // rather than synchronously from `fetch()` -- let it run before
      // checking how many times it fired.
      await flushMicrotasks();
      expect(CoopModulesAPI.get).toHaveBeenCalledTimes(1);

      request.resolve({
        data: {
          payload: [{ key: 'producers', name: 'Producers', enabled: true }],
        },
      });

      const [firstResult, secondResult] = await Promise.all([first, second]);

      expect(CoopModulesAPI.get).toHaveBeenCalledTimes(1);
      expect(firstResult).toBe(secondResult);
      expect(store.getModules).toEqual([
        expect.objectContaining({ key: 'producers', enabled: true }),
      ]);
    });

    it.each([
      [401, 'permission'],
      [403, 'permission'],
      [500, 'server'],
    ])('maps a %i response to fetchError %j', async (status, expected) => {
      CoopModulesAPI.get.mockRejectedValueOnce({ response: { status } });

      const store = useCoopModulesStore();
      await store.fetch();

      expect(store.getFetchError).toBe(expected);
    });

    it('resets fetchError to null after a subsequent successful fetch', async () => {
      const store = useCoopModulesStore();

      CoopModulesAPI.get.mockRejectedValueOnce({ response: { status: 500 } });
      await store.fetch();
      expect(store.getFetchError).toBe('server');

      CoopModulesAPI.get.mockResolvedValueOnce({ data: { payload: [] } });
      await store.fetch();
      expect(store.getFetchError).toBeNull();
    });

    it('still dedupes concurrent fetch() calls onto a single GET when a toggle is already queued, and does not let a stale response revert the toggle', async () => {
      const toggleRequest = createDeferred();
      CoopModulesAPI.update.mockReturnValueOnce(toggleRequest.promise);

      // Models the canonical server-side state as a plain variable rather
      // than a fixed deferred payload: the GET's response reflects
      // whatever's true at the moment `.get()` is actually CALLED, not at
      // the moment `fetch()` was called -- exactly the distinction that
      // matters for this regression. Starts `true` (pre-toggle) and flips
      // to `false` once the toggle "commits" below.
      let producersEnabledOnServer = true;
      CoopModulesAPI.get.mockImplementationOnce(() =>
        Promise.resolve({
          data: {
            payload: [
              {
                key: 'producers',
                name: 'Producers',
                enabled: producersEnabledOnServer,
              },
            ],
          },
        })
      );

      const store = useCoopModulesStore();

      // Occupy the mutation queue with a pending toggle before fetch() is
      // ever called -- simulates a remount firing fetch() while a toggle
      // triggered just before it is still in flight.
      const toggling = store.toggle('producers', false);

      const first = store.fetch();
      const second = store.fetch();

      // The GET must not be issued while the toggle it's queued behind is
      // still pending -- this is what closes the direction-B race: if the
      // GET were sent now, it would read the pre-toggle server state.
      // Flush microtasks first so the assertion also rejects issuance
      // deferred by a fixed number of ticks rather than truly gated on
      // the toggle settling.
      await flushMicrotasks();
      expect(CoopModulesAPI.get).not.toHaveBeenCalled();

      // The toggle "commits" on the server -- flip the canonical state the
      // GET will observe once it's actually issued.
      producersEnabledOnServer = false;
      toggleRequest.resolve({
        data: {
          payload: [{ key: 'producers', name: 'Producers', enabled: false }],
        },
      });
      await toggling;

      const [firstResult, secondResult] = await Promise.all([first, second]);

      // Both fetch() callers still dedup onto the single GET, now issued
      // only once the queued toggle ahead of it settled.
      expect(CoopModulesAPI.get).toHaveBeenCalledTimes(1);
      expect(firstResult).toBe(secondResult);

      // Because the GET was gated behind the toggle, it observed the
      // already-committed state -- the final list reflects the toggle's
      // result, not a stale pre-toggle snapshot silently reverting it.
      expect(store.getModules).toEqual([
        expect.objectContaining({ key: 'producers', enabled: false }),
      ]);
    });
  });

  describe('toggle', () => {
    it("returns the caller's requested value alongside the resolver's actual value", async () => {
      // The resolver can decline the requested change (dependency cascade,
      // kill switch, etc.) -- `resolved` reflects what the server actually
      // settled on, which can differ from `requested`.
      CoopModulesAPI.update.mockResolvedValueOnce({
        data: {
          payload: [{ key: 'producers', name: 'Producers', enabled: false }],
        },
      });

      const store = useCoopModulesStore();
      const result = await store.toggle('producers', true);

      expect(result).toEqual({ requested: true, resolved: false });
    });

    it('serializes toggle PATCHes so a second toggle is never issued before the first settles', async () => {
      const firstRequest = createDeferred();
      const secondRequest = createDeferred();

      CoopModulesAPI.update
        .mockImplementationOnce(() => firstRequest.promise)
        .mockImplementationOnce(() => secondRequest.promise);

      const store = useCoopModulesStore();

      const togglingA = store.toggle('producers', false);
      const togglingB = store.toggle('market', true);

      await flushMicrotasks();

      // The second toggle's PATCH must stay queued while the first is
      // in-flight -- otherwise their responses could land out of order and
      // regress the list to a stale snapshot.
      expect(CoopModulesAPI.update).toHaveBeenCalledTimes(1);
      expect(CoopModulesAPI.update).toHaveBeenNthCalledWith(1, 'producers', {
        enabled: false,
      });

      firstRequest.resolve({
        data: {
          payload: [
            { key: 'producers', name: 'Producers', enabled: false },
            { key: 'market', name: 'Market', enabled: false },
          ],
        },
      });
      await togglingA;
      await flushMicrotasks();

      // Only now -- after the first toggle settled -- may the second PATCH
      // be issued.
      expect(CoopModulesAPI.update).toHaveBeenCalledTimes(2);
      expect(CoopModulesAPI.update).toHaveBeenNthCalledWith(2, 'market', {
        enabled: true,
      });

      secondRequest.resolve({
        data: {
          payload: [
            { key: 'producers', name: 'Producers', enabled: false },
            { key: 'market', name: 'Market', enabled: true },
          ],
        },
      });
      await togglingB;

      // The list matches the last server response -- never a mix of a
      // stale snapshot and a newer one.
      expect(store.getModules).toEqual([
        expect.objectContaining({ key: 'producers', enabled: false }),
        expect.objectContaining({ key: 'market', enabled: true }),
      ]);
    });

    it('still resolves a queued toggle after an earlier queued toggle fails', async () => {
      const firstRequest = createDeferred();
      const secondRequest = createDeferred();

      CoopModulesAPI.update
        .mockImplementationOnce(() => firstRequest.promise)
        .mockImplementationOnce(() => secondRequest.promise);

      const store = useCoopModulesStore();

      const togglingA = store.toggle('producers', false);
      const togglingB = store.toggle('market', true);

      firstRequest.reject({ response: { status: 500 } });
      await expect(togglingA).rejects.toThrow();

      secondRequest.resolve({
        data: {
          payload: [{ key: 'market', name: 'Market', enabled: true }],
        },
      });

      await expect(togglingB).resolves.toEqual({
        requested: true,
        resolved: true,
      });
      expect(store.getModules).toEqual([
        expect.objectContaining({ key: 'market', enabled: true }),
      ]);
    });
  });

  describe('fetch/toggle ordering', () => {
    it('does not let a fetch() GET response clobber a toggle queued behind it', async () => {
      const getRequest = createDeferred();
      CoopModulesAPI.get.mockReturnValueOnce(getRequest.promise);

      const patchRequest = createDeferred();
      CoopModulesAPI.update.mockReturnValueOnce(patchRequest.promise);

      const store = useCoopModulesStore();

      const fetching = store.fetch();
      const toggling = store.toggle('producers', false);

      await flushMicrotasks();

      // The toggle's PATCH must not be issued until the fetch's GET
      // response has been applied to `this.modules` -- otherwise a
      // fetch() issued before the toggle could still have its GET
      // response *land* after the toggle's PATCH response and clobber
      // the freshly-toggled list.
      expect(CoopModulesAPI.update).not.toHaveBeenCalled();

      // Resolve the GET *after* the toggle was already queued, simulating
      // exactly the race this fix closes: a stale pre-toggle snapshot
      // arriving late.
      getRequest.resolve({
        data: {
          payload: [{ key: 'producers', name: 'Producers', enabled: true }],
        },
      });
      await fetching;
      await flushMicrotasks();

      // Only now -- after the fetch's response settled -- may the queued
      // toggle's PATCH be issued.
      expect(CoopModulesAPI.update).toHaveBeenCalledTimes(1);

      patchRequest.resolve({
        data: {
          payload: [{ key: 'producers', name: 'Producers', enabled: false }],
        },
      });
      await toggling;

      // The list reflects the toggle's response -- the earlier fetch
      // snapshot never overwrites it, no matter when its own request was
      // issued or resolved.
      expect(store.getModules).toEqual([
        expect.objectContaining({ key: 'producers', enabled: false }),
      ]);
    });
  });
});
