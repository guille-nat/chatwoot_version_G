<script setup>
import { computed, watch, ref } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { dynamicTime } from 'shared/helpers/timeHelper';

import Button from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import WootLabel from 'dashboard/components-next/label/Label.vue';
import ProducerFormDialog from 'dashboard/components-next/Coop/Producers/ProducerFormDialog.vue';
import ConfirmProducerDeleteDialog from 'dashboard/components-next/Coop/Producers/ConfirmProducerDeleteDialog.vue';
import { useCoopProducersStore } from 'dashboard/stores/coopProducers';

const route = useRoute();
const router = useRouter();
const { t } = useI18n();

const producersStore = useCoopProducersStore();

const formDialogRef = ref(null);
const deleteDialogRef = ref(null);

const producerId = computed(() => Number(route.params.producerId));
const producer = computed(() => producersStore.getRecord(producerId.value));
const uiFlags = computed(() => producersStore.getUIFlags);
const isFetching = computed(() => uiFlags.value.fetchingItem);
const isModuleDisabled = computed(() => producersStore.isModuleDisabled);
const hasProducer = computed(() => Boolean(producer.value?.id));
const showInitialLoadingState = computed(
  () => !hasProducer.value && isFetching.value
);

const producerTypeLabel = computed(() =>
  producer.value?.producerType === 'company'
    ? t('COOP_PRODUCERS.TYPE.COMPANY')
    : t('COOP_PRODUCERS.TYPE.INDIVIDUAL')
);

const statusLabel = computed(() =>
  producer.value?.status === 'inactive'
    ? t('COOP_PRODUCERS.STATUS.INACTIVE')
    : t('COOP_PRODUCERS.STATUS.ACTIVE')
);

const goToProducersIndex = () => {
  router.push({
    name: 'coop_producers_dashboard_index',
    params: { accountId: route.params.accountId },
  });
};

const goBack = () => {
  if (window.history.state?.back) {
    router.back();
    return;
  }
  goToProducersIndex();
};

const openEditDialog = () => {
  formDialogRef.value?.open(producer.value);
};

const openDeleteDialog = () => {
  deleteDialogRef.value?.open(producer.value);
};

const handleProducerDeleted = () => {
  goToProducersIndex();
};

const handleProducerSaved = () => {
  producersStore.show(producerId.value);
};

watch(
  producerId,
  async id => {
    if (!id) return;
    await producersStore.show(id);
  },
  { immediate: true }
);
</script>

<template>
  <div class="flex flex-col w-full h-full overflow-hidden bg-n-surface-1">
    <header
      class="flex items-center gap-3 flex-shrink-0 px-6 py-4 border-b border-n-weak"
    >
      <Button
        icon="i-lucide-arrow-left"
        variant="ghost"
        slate
        sm
        @click="goBack"
      />
      <h1 class="text-xl font-medium truncate text-n-slate-12">
        {{ producer?.businessName || t('COOP_PRODUCERS.HEADER') }}
      </h1>
    </header>

    <main class="flex-1 px-6 py-4 overflow-y-auto">
      <div class="w-full max-w-3xl mx-auto">
        <div
          v-if="isModuleDisabled"
          class="flex flex-col items-center justify-center gap-3 px-6 py-24 text-center rounded-2xl border border-n-weak bg-n-solid-2"
        >
          <Icon icon="i-lucide-lock" class="size-6 text-n-slate-10" />
          <span class="text-lg font-medium text-n-slate-12">
            {{ t('COOP_PRODUCERS.MODULE_DISABLED.TITLE') }}
          </span>
          <p class="max-w-md text-sm text-n-slate-11">
            {{ t('COOP_PRODUCERS.MODULE_DISABLED.SUBTITLE') }}
          </p>
        </div>

        <div
          v-else-if="showInitialLoadingState"
          class="flex flex-col items-center justify-center gap-3 py-24 text-n-slate-11"
        >
          <Spinner />
          <span class="text-sm">{{ t('COOP_PRODUCERS.DETAIL.LOADING') }}</span>
        </div>

        <div
          v-else-if="!hasProducer"
          class="flex flex-col items-center justify-center gap-3 px-6 py-24 text-center rounded-2xl border border-n-weak bg-n-solid-2"
        >
          <span class="text-lg font-medium text-n-slate-12">
            {{ t('COOP_PRODUCERS.DETAIL.EMPTY_STATE.TITLE') }}
          </span>
          <p class="max-w-md text-sm text-n-slate-11">
            {{ t('COOP_PRODUCERS.DETAIL.EMPTY_STATE.SUBTITLE') }}
          </p>
        </div>

        <div v-else class="flex flex-col gap-6">
          <div
            class="flex flex-col gap-4 p-6 border rounded-2xl border-n-weak bg-n-solid-2"
          >
            <div class="flex items-start justify-between gap-4">
              <div class="flex flex-col gap-1 min-w-0">
                <span class="text-lg font-medium truncate text-n-slate-12">
                  {{ producer.businessName }}
                </span>
                <span v-if="producer.tradeName" class="text-sm text-n-slate-11">
                  {{ producer.tradeName }}
                </span>
              </div>
              <WootLabel
                :label="statusLabel"
                :color="producer.status === 'active' ? 'teal' : 'slate'"
                compact
              />
            </div>

            <dl class="grid grid-cols-1 gap-4 sm:grid-cols-2">
              <div class="flex flex-col gap-0.5">
                <dt class="text-xs text-n-slate-10">
                  {{ t('COOP_PRODUCERS.FORM.FIELDS.CUIT') }}
                </dt>
                <dd class="text-sm text-n-slate-12">
                  {{ producer.cuitFormatted || '—' }}
                </dd>
              </div>
              <div class="flex flex-col gap-0.5">
                <dt class="text-xs text-n-slate-10">
                  {{ t('COOP_PRODUCERS.FORM.FIELDS.PRODUCER_TYPE') }}
                </dt>
                <dd class="text-sm text-n-slate-12">
                  {{ producerTypeLabel }}
                </dd>
              </div>
              <div class="flex flex-col gap-0.5">
                <dt class="text-xs text-n-slate-10">
                  {{ t('COOP_PRODUCERS.FORM.FIELDS.PRIMARY_PHONE') }}
                </dt>
                <dd class="text-sm text-n-slate-12">
                  {{ producer.primaryPhone || '—' }}
                </dd>
              </div>
              <div class="flex flex-col gap-0.5">
                <dt class="text-xs text-n-slate-10">
                  {{ t('COOP_PRODUCERS.FORM.FIELDS.EMAIL') }}
                </dt>
                <dd class="text-sm text-n-slate-12">
                  {{ producer.email || '—' }}
                </dd>
              </div>
              <div class="flex flex-col gap-0.5">
                <dt class="text-xs text-n-slate-10">
                  {{ t('COOP_PRODUCERS.FORM.FIELDS.EXTERNAL_REF') }}
                </dt>
                <dd class="text-sm text-n-slate-12">
                  {{ producer.externalRef || '—' }}
                </dd>
              </div>
              <div v-if="producer.createdAt" class="flex flex-col gap-0.5">
                <dt class="text-xs text-n-slate-10">
                  {{ t('COOP_PRODUCERS.DETAIL.FIELDS.CREATED_AT') }}
                </dt>
                <dd class="text-sm text-n-slate-12">
                  {{ dynamicTime(producer.createdAt) }}
                </dd>
              </div>
            </dl>

            <div v-if="producer.notes" class="flex flex-col gap-0.5">
              <dt class="text-xs text-n-slate-10">
                {{ t('COOP_PRODUCERS.FORM.FIELDS.NOTES') }}
              </dt>
              <dd class="text-sm whitespace-pre-line text-n-slate-12">
                {{ producer.notes }}
              </dd>
            </div>

            <div class="flex items-center gap-3 pt-4 border-t border-n-weak">
              <Button
                :label="t('COOP_PRODUCERS.ACTIONS.EDIT')"
                icon="i-lucide-pencil"
                variant="faded"
                color="slate"
                @click="openEditDialog"
              />
              <Button
                :label="t('COOP_PRODUCERS.ACTIONS.DELETE')"
                icon="i-lucide-trash-2"
                color="ruby"
                variant="faded"
                @click="openDeleteDialog"
              />
            </div>
          </div>
        </div>
      </div>
    </main>

    <ProducerFormDialog ref="formDialogRef" @saved="handleProducerSaved" />
    <ConfirmProducerDeleteDialog
      ref="deleteDialogRef"
      @deleted="handleProducerDeleted"
    />
  </div>
</template>
