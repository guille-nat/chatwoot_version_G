import camelcaseKeys from 'camelcase-keys';
import snakecaseKeys from 'snakecase-keys';
import ProducerAPI from 'dashboard/api/coop/producers';
import { createStore } from 'dashboard/store/storeFactory';
import { normalizeCuit } from 'dashboard/helper/coopCuitHelper';

const camelizeProducer = data =>
  camelcaseKeys(data || {}, { deep: true, stopPaths: ['custom_attributes'] });

const buildProducerRequestPayload = ({ customAttributes, cuit, ...rest }) => ({
  producer: {
    ...snakecaseKeys(rest, { deep: true }),
    cuit: cuit ? normalizeCuit(cuit) : null,
    ...(customAttributes && { custom_attributes: customAttributes }),
  },
});

// The generic `throwErrorMessage` helper (used by the rest of the app) only
// keeps the error message string, which is enough for a toast but not for
// this form: the backend's 422 body is `{ message, attributes: ["cuit"] }`
// (see custom/.../request_exception_handler.rb#render_record_invalid) and
// ProducerFormDialog needs `attributes` to know which field to highlight.
const throwProducerError = error => {
  const data = error?.response?.data;
  const message =
    data?.message ||
    data?.error ||
    (Array.isArray(data?.errors) ? data.errors[0] : null) ||
    error?.message ||
    'Unknown error';

  const richError = new Error(message);
  richError.attributes = data?.attributes || [];
  richError.errorCode = data?.error_code;
  throw richError;
};

const isModuleDisabledError = error =>
  error?.response?.data?.error_code === 'module_disabled';

export const useCoopProducersStore = createStore({
  name: 'coopProducers',
  type: 'pinia',
  API: ProducerAPI,
  state: () => ({
    moduleDisabled: false,
  }),

  getters: {
    getProducersList: state =>
      [...state.records].sort((a, b) =>
        (a.businessName || '').localeCompare(b.businessName || '')
      ),
    isModuleDisabled: state => state.moduleDisabled,
  },

  actions: () => ({
    async get() {
      this.setUIFlag({ fetchingList: true });
      try {
        const {
          data: { payload },
        } = await ProducerAPI.get();
        this.records = camelizeProducer(payload);
        this.moduleDisabled = false;
        return this.records;
      } catch (error) {
        if (isModuleDisabledError(error)) {
          this.records = [];
          this.moduleDisabled = true;
          return this.records;
        }
        return throwProducerError(error);
      } finally {
        this.setUIFlag({ fetchingList: false });
      }
    },

    async show(id) {
      this.setUIFlag({ fetchingItem: true });
      try {
        const {
          data: { payload },
        } = await ProducerAPI.show(id);
        const producer = camelizeProducer(payload);
        const index = this.records.findIndex(r => r.id === producer.id);
        if (index === -1) this.records.push(producer);
        else this.records[index] = producer;
        this.moduleDisabled = false;
        return producer;
      } catch (error) {
        if (isModuleDisabledError(error)) {
          this.moduleDisabled = true;
          return null;
        }
        return throwProducerError(error);
      } finally {
        this.setUIFlag({ fetchingItem: false });
      }
    },

    async create(producerAttrs) {
      this.setUIFlag({ creatingItem: true });
      try {
        const {
          data: { payload },
        } = await ProducerAPI.create(
          buildProducerRequestPayload(producerAttrs)
        );
        const producer = camelizeProducer(payload);
        this.records.push(producer);
        return producer;
      } catch (error) {
        return throwProducerError(error);
      } finally {
        this.setUIFlag({ creatingItem: false });
      }
    },

    async update({ id, ...producerAttrs }) {
      this.setUIFlag({ updatingItem: true });
      try {
        const {
          data: { payload },
        } = await ProducerAPI.update(
          id,
          buildProducerRequestPayload(producerAttrs)
        );
        const producer = camelizeProducer(payload);
        const index = this.records.findIndex(r => r.id === producer.id);
        if (index !== -1) this.records[index] = producer;
        return producer;
      } catch (error) {
        return throwProducerError(error);
      } finally {
        this.setUIFlag({ updatingItem: false });
      }
    },

    async delete(id) {
      this.setUIFlag({ deletingItem: true });
      try {
        await ProducerAPI.delete(id);
        this.records = this.records.filter(r => r.id !== Number(id));
        return Number(id);
      } catch (error) {
        return throwProducerError(error);
      } finally {
        this.setUIFlag({ deletingItem: false });
      }
    },
  }),
});
