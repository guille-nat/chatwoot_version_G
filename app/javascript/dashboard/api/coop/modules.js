/* global axios */
import ApiClient from '../ApiClient';

// coopModules.js serializes every GET and PATCH through one total-order
// queue so out-of-order full-list responses can't clobber the store --
// which means one stalled request (axios has no default timeout) would
// block every later queued read/write forever. Bound each request so a
// hang settles into the existing error paths (fetchError / toggle error
// toast) and the queue keeps draining.
const REQUEST_TIMEOUT = 20000;

// Other clients (`TeamsAPI`, `ReportsAPI`) add differently-named methods
// with custom axios calls for non-generic endpoints; this file instead
// shadows the base `ApiClient` `get()`/`update()` names themselves, solely
// to attach `{ timeout: REQUEST_TIMEOUT }`. Neither that shadowing nor the
// timeout option has precedent under dashboard/api -- both are new and
// local to this client, for the reason above.
class CoopModulesAPI extends ApiClient {
  constructor() {
    super('coop/modules', { accountScoped: true });
  }

  get() {
    return axios.get(this.url, { timeout: REQUEST_TIMEOUT });
  }

  update(key, data) {
    return axios.patch(`${this.url}/${key}`, data, {
      timeout: REQUEST_TIMEOUT,
    });
  }
}

export default new CoopModulesAPI();
