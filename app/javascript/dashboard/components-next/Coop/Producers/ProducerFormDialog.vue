<script setup>
import { computed, reactive, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';

import Button from 'dashboard/components-next/button/Button.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Select from 'dashboard/components-next/select/Select.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import { isValidCuit, normalizeCuit } from 'dashboard/helper/coopCuitHelper';
import { useCoopProducersStore } from 'dashboard/stores/coopProducers';

const emit = defineEmits(['saved']);

const { t } = useI18n();
const producersStore = useCoopProducersStore();

const dialogRef = ref(null);
const cuitServerError = ref('');

const createEmptyForm = () => ({
  id: null,
  businessName: '',
  tradeName: '',
  producerType: 'individual',
  cuit: '',
  primaryPhone: '',
  email: '',
  status: 'active',
  externalRef: '',
  notes: '',
});

const form = reactive(createEmptyForm());

const isEditing = computed(() => !!form.id);
const isSaving = computed(
  () =>
    producersStore.getUIFlags.creatingItem ||
    producersStore.getUIFlags.updatingItem
);

const producerTypeOptions = computed(() => [
  { value: 'individual', label: t('COOP_PRODUCERS.TYPE.INDIVIDUAL') },
  { value: 'company', label: t('COOP_PRODUCERS.TYPE.COMPANY') },
]);

const statusOptions = computed(() => [
  { value: 'active', label: t('COOP_PRODUCERS.STATUS.ACTIVE') },
  { value: 'inactive', label: t('COOP_PRODUCERS.STATUS.INACTIVE') },
]);

// Client-side mirror of the backend's mod-11 check (CoopCore::Producer::Cuit)
// so the field reacts as soon as 11 digits are typed, without waiting on a
// round trip. It only fires once a full CUIT length is reached so partial
// input while typing isn't flagged as an error.
const cuitClientError = computed(() => {
  const digits = normalizeCuit(form.cuit);
  if (!digits || digits.length < 11) return '';
  return isValidCuit(form.cuit)
    ? ''
    : t('COOP_PRODUCERS.FORM.VALIDATION.CUIT_INVALID');
});

const cuitMessage = computed(
  () => cuitClientError.value || cuitServerError.value
);

watch(
  () => form.cuit,
  () => {
    cuitServerError.value = '';
  }
);

const isFormInvalid = computed(
  () => !form.businessName.trim() || !!cuitClientError.value
);

const resetForm = () => {
  Object.assign(form, createEmptyForm());
  cuitServerError.value = '';
};

const open = (producer = null) => {
  resetForm();
  if (producer?.id) {
    Object.assign(form, {
      id: producer.id,
      businessName: producer.businessName || '',
      tradeName: producer.tradeName || '',
      producerType: producer.producerType || 'individual',
      cuit: producer.cuit || '',
      primaryPhone: producer.primaryPhone || '',
      email: producer.email || '',
      status: producer.status || 'active',
      externalRef: producer.externalRef || '',
      notes: producer.notes || '',
    });
  }
  dialogRef.value?.open();
};

const closeDialog = () => {
  dialogRef.value?.close();
};

const buildPayload = () => ({
  businessName: form.businessName.trim(),
  tradeName: form.tradeName.trim() || null,
  producerType: form.producerType,
  cuit: form.cuit ? normalizeCuit(form.cuit) : null,
  primaryPhone: form.primaryPhone.trim() || null,
  email: form.email.trim() || null,
  status: form.status,
  externalRef: form.externalRef.trim() || null,
  notes: form.notes.trim() || null,
});

const handleConfirm = async () => {
  if (isFormInvalid.value || isSaving.value) return;

  try {
    const producer = isEditing.value
      ? await producersStore.update({ id: form.id, ...buildPayload() })
      : await producersStore.create(buildPayload());

    useAlert(
      t(
        isEditing.value
          ? 'COOP_PRODUCERS.FORM.MESSAGES.UPDATE_SUCCESS'
          : 'COOP_PRODUCERS.FORM.MESSAGES.CREATE_SUCCESS'
      )
    );
    emit('saved', producer);
    closeDialog();
  } catch (error) {
    if (error.attributes?.includes('cuit')) {
      cuitServerError.value = error.message;
      return;
    }

    useAlert(
      error.message ||
        t(
          isEditing.value
            ? 'COOP_PRODUCERS.FORM.MESSAGES.UPDATE_ERROR'
            : 'COOP_PRODUCERS.FORM.MESSAGES.CREATE_ERROR'
        )
    );
  }
};

defineExpose({ open });
</script>

<template>
  <Dialog
    ref="dialogRef"
    width="2xl"
    overflow-y-auto
    @confirm="handleConfirm"
    @close="resetForm"
  >
    <div class="flex flex-col gap-6">
      <span class="py-1 text-sm font-medium text-n-slate-12">
        {{
          isEditing
            ? t('COOP_PRODUCERS.FORM.EDIT_TITLE')
            : t('COOP_PRODUCERS.FORM.CREATE_TITLE')
        }}
      </span>
      <div class="grid w-full grid-cols-1 gap-4 sm:grid-cols-2">
        <Input
          v-model="form.businessName"
          :label="t('COOP_PRODUCERS.FORM.FIELDS.BUSINESS_NAME')"
          :placeholder="t('COOP_PRODUCERS.FORM.FIELDS.BUSINESS_NAME')"
          :disabled="isSaving"
          autofocus
        />
        <Input
          v-model="form.tradeName"
          :label="t('COOP_PRODUCERS.FORM.FIELDS.TRADE_NAME')"
          :placeholder="t('COOP_PRODUCERS.FORM.FIELDS.TRADE_NAME')"
          :disabled="isSaving"
        />
        <div class="flex flex-col gap-1">
          <span class="text-heading-3 text-n-slate-12">
            {{ t('COOP_PRODUCERS.FORM.FIELDS.PRODUCER_TYPE') }}
          </span>
          <Select
            v-model="form.producerType"
            :options="producerTypeOptions"
            :disabled="isSaving"
            class="w-full"
          />
        </div>
        <div class="flex flex-col gap-1">
          <span class="text-heading-3 text-n-slate-12">
            {{ t('COOP_PRODUCERS.FORM.FIELDS.STATUS') }}
          </span>
          <Select
            v-model="form.status"
            :options="statusOptions"
            :disabled="isSaving"
            class="w-full"
          />
        </div>
        <Input
          v-model="form.cuit"
          :label="t('COOP_PRODUCERS.FORM.FIELDS.CUIT')"
          :placeholder="t('COOP_PRODUCERS.FORM.PLACEHOLDERS.CUIT')"
          :disabled="isSaving"
          :message="cuitMessage"
          :message-type="cuitMessage ? 'error' : 'info'"
        />
        <Input
          v-model="form.primaryPhone"
          type="tel"
          :label="t('COOP_PRODUCERS.FORM.FIELDS.PRIMARY_PHONE')"
          :placeholder="t('COOP_PRODUCERS.FORM.FIELDS.PRIMARY_PHONE')"
          :disabled="isSaving"
        />
        <Input
          v-model="form.email"
          type="email"
          :label="t('COOP_PRODUCERS.FORM.FIELDS.EMAIL')"
          :placeholder="t('COOP_PRODUCERS.FORM.FIELDS.EMAIL')"
          :disabled="isSaving"
        />
        <Input
          v-model="form.externalRef"
          :label="t('COOP_PRODUCERS.FORM.FIELDS.EXTERNAL_REF')"
          :placeholder="t('COOP_PRODUCERS.FORM.FIELDS.EXTERNAL_REF')"
          :disabled="isSaving"
        />
      </div>
      <TextArea
        v-model="form.notes"
        :label="t('COOP_PRODUCERS.FORM.FIELDS.NOTES')"
        :placeholder="t('COOP_PRODUCERS.FORM.FIELDS.NOTES')"
        :disabled="isSaving"
        :max-length="500"
        class="w-full"
        show-character-count
        auto-height
      />
    </div>

    <template #footer>
      <div class="flex items-center justify-between w-full gap-3">
        <Button
          :label="t('DIALOG.BUTTONS.CANCEL')"
          variant="link"
          type="reset"
          class="h-10 hover:!no-underline hover:text-n-brand"
          @click="closeDialog"
        />
        <Button
          :label="t('COOP_PRODUCERS.FORM.ACTIONS.SAVE')"
          color="blue"
          type="submit"
          :disabled="isFormInvalid || isSaving"
          :is-loading="isSaving"
        />
      </div>
    </template>
  </Dialog>
</template>
