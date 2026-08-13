import { frontendURL } from '../../../../helper/URLHelper';

import SettingsWrapper from '../SettingsWrapper.vue';
import CoopModulesIndex from './Index.vue';

// This is the meta-screen for the module registry itself (mirrors
// `coop_module = false` on Api::V1::Accounts::Coop::ModulesController) --
// it must never be gated behind a coop module. It must also work on
// community self-hosted, so no `installationTypes` restriction.
//
// Unlike a plain Chatwoot `administrator`-only screen, CoopFlow staff can be
// granted `modules_read` / `modules_manage` on a Chatwoot `agent` account
// (see CoopCore::StaffRole). Mirrors the Producers route
// (dashboard/routes/dashboard/coop/routes.js#commonMeta): the router only
// coarse-gates on Chatwoot's `permissions` (helper/routeHelpers.js
// #routeIsAccessibleFor); the real enforcement is the backend (403) plus
// the in-page `fetchError === 'permission'` state.
export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/modules'),
      component: SettingsWrapper,
      children: [
        {
          path: '',
          redirect: to => {
            return { name: 'coop_modules_settings_index', params: to.params };
          },
        },
        {
          path: 'list',
          name: 'coop_modules_settings_index',
          meta: {
            permissions: ['administrator', 'agent'],
          },
          component: CoopModulesIndex,
        },
      ],
    },
  ],
};
