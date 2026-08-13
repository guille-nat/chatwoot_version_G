<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import { useCoopProducersStore } from 'dashboard/stores/coopProducers';

const emit = defineEmits(['deleted']);

const { t } = useI18n();
const producersStore = useCoopProducersStore();

const dialogRef = ref(null);
const producer = ref(null);

const isDeleting = computed(() => producersStore.getUIFlags.deletingItem);

const description = computed(() =>
  producer.value?.businessName
    ? t('COOP_PRODUCERS.DELETE.DESCRIPTION_WITH_NAME', {
        producerName: producer.value.businessName,
      })
    : t('COOP_PRODUCERS.DELETE.DESCRIPTION')
);

const open = record => {
  producer.value = record;
  dialogRef.value?.open();
};

const handleConfirm = async () => {
  if (!producer.value?.id) return;

  try {
    const deletedId = await producersStore.delete(producer.value.id);
    useAlert(t('COOP_PRODUCERS.DELETE.MESSAGES.SUCCESS'));
    dialogRef.value?.close();
    emit('deleted', deletedId);
  } catch (error) {
    useAlert(error.message || t('COOP_PRODUCERS.DELETE.MESSAGES.ERROR'));
  }
};

defineExpose({ open });
</script>

<template>
  <Dialog
    ref="dialogRef"
    type="alert"
    :title="t('COOP_PRODUCERS.DELETE.TITLE')"
    :description="description"
    :confirm-button-label="t('COOP_PRODUCERS.DELETE.CONFIRM')"
    :is-loading="isDeleting"
    @confirm="handleConfirm"
  />
</template>
