import ApiClient from '../ApiClient';

class CoopProducersAPI extends ApiClient {
  constructor() {
    super('coop/producers', { accountScoped: true });
  }
}

export default new CoopProducersAPI();
