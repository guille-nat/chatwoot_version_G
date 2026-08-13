import { frontendURL } from '../../../helper/URLHelper';
import ProducersIndex from './pages/ProducersIndex.vue';
import ProducerDetailView from './pages/ProducerDetailView.vue';

// Unlike Companies (dashboard/routes/dashboard/companies/routes.js), this
// intentionally has NO `featureFlag` / `installationTypes` in meta: Coop
// modules are a dynamic, per-account, API-driven gate (CoopCore::Feature),
// not Chatwoot's static FEATURE_FLAGS enum, and CoopFlow must keep working on
// community self-hosted installs. The router only enforces `permissions`
// (see helper/routeHelpers.js#routeIsAccessibleFor); the producers module
// gate itself is enforced by the backend (403 module_disabled) and rendered
// as a friendly empty state by the page components, not by route meta.
const commonMeta = {
  permissions: ['administrator', 'agent'],
};

export const routes = [
  {
    path: frontendURL('accounts/:accountId/coop/producers'),
    component: ProducersIndex,
    meta: commonMeta,
    children: [
      {
        path: '',
        name: 'coop_producers_dashboard_index',
        component: ProducersIndex,
        meta: commonMeta,
      },
    ],
  },
  {
    path: frontendURL('accounts/:accountId/coop/producers/:producerId'),
    component: ProducerDetailView,
    meta: commonMeta,
    children: [
      {
        path: '',
        name: 'coop_producers_dashboard_show',
        component: ProducerDetailView,
        meta: commonMeta,
      },
    ],
  },
];
