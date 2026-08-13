import ApiClient from '../ApiClient';

class CoopModulesAPI extends ApiClient {
  constructor() {
    super('coop/modules', { accountScoped: true });
  }
}

export default new CoopModulesAPI();
