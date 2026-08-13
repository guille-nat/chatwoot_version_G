import { defineStore } from 'pinia';
import camelcaseKeys from 'camelcase-keys';
import CoopModulesAPI from 'dashboard/api/coop/modules';

// CoopFlow modules are keyed by `key` (e.g. "producers"), not `id` --
// createStore's generic CRUD factory assumes an `id`-keyed record list, so
// this store is defined directly instead of going through it.
export const useCoopModulesStore = defineStore('coopModules', {
  state: () => ({
    modules: [],
    uiFlags: {
      fetchingList: false,
    },
  }),

  getters: {
    getModules: state => state.modules,
    getUIFlags: state => state.uiFlags,
    isEnabled: state => key =>
      state.modules.find(coopModule => coopModule.key === key)?.enabled ??
      false,
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
        return this.modules;
      } catch (error) {
        // The sidebar calls `fetch()` fire-and-forget on mount -- a modules
        // fetch failure must never break the sidebar, so fail closed
        // (`modules` stays whatever it already was, i.e. `[]` on first load)
        // and just log instead of rejecting.
        // eslint-disable-next-line no-console
        console.error('[coopModules] Failed to fetch modules', error);
        return this.modules;
      } finally {
        this.setUIFlag({ fetchingList: false });
      }
    },
  },
});
