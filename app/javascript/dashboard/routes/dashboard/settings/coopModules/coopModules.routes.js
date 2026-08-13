import { frontendURL } from '../../../../helper/URLHelper';

import SettingsWrapper from '../SettingsWrapper.vue';
import CoopModulesIndex from './Index.vue';

// This is the meta-screen for the module registry itself (mirrors
// `coop_module = false` on Api::V1::Accounts::Coop::ModulesController) --
// it must never be gated behind a coop module, only behind the
// administrator role. It must also work on community self-hosted, so no
// `installationTypes` restriction.
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
            permissions: ['administrator'],
          },
          component: CoopModulesIndex,
        },
      ],
    },
  ],
};
