<script setup>
import { computed, onMounted, ref } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';

import Button from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import WootLabel from 'dashboard/components-next/label/Label.vue';
import {
  BaseTable,
  BaseTableRow,
  BaseTableCell,
} from 'dashboard/components-next/table';
import ProducerFormDialog from 'dashboard/components-next/Coop/Producers/ProducerFormDialog.vue';
import ConfirmProducerDeleteDialog from 'dashboard/components-next/Coop/Producers/ConfirmProducerDeleteDialog.vue';
import { useCoopProducersStore } from 'dashboard/stores/coopProducers';

const route = useRoute();
const router = useRouter();
const { t } = useI18n();

const producersStore = useCoopProducersStore();

const formDialogRef = ref(null);
const deleteDialogRef = ref(null);

const producers = computed(() => producersStore.getProducersList);
const uiFlags = computed(() => producersStore.getUIFlags);
const isFetchingList = computed(() => uiFlags.value.fetchingList);
const isModuleDisabled = computed(() => producersStore.isModuleDisabled);
const fetchError = computed(() => producersStore.getFetchError);
const isPermissionError = computed(() => fetchError.value === 'permission');
const canCreate = computed(
  () => !isModuleDisabled.value && !isPermissionError.value
);

const tableHeaders = computed(() => [
  t('COOP_PRODUCERS.LIST.TABLE_HEADER.BUSINESS_NAME'),
  t('COOP_PRODUCERS.LIST.TABLE_HEADER.CUIT'),
  t('COOP_PRODUCERS.LIST.TABLE_HEADER.TYPE'),
  t('COOP_PRODUCERS.LIST.TABLE_HEADER.STATUS'),
  t('COOP_PRODUCERS.LIST.TABLE_HEADER.PHONE'),
  t('COOP_PRODUCERS.LIST.ACTIONS'),
]);

const producerTypeLabel = type =>
  type === 'company'
    ? t('COOP_PRODUCERS.TYPE.COMPANY')
    : t('COOP_PRODUCERS.TYPE.INDIVIDUAL');

const statusLabel = status =>
  status === 'inactive'
    ? t('COOP_PRODUCERS.STATUS.INACTIVE')
    : t('COOP_PRODUCERS.STATUS.ACTIVE');

const noDataMessage = computed(() =>
  !producers.value.length && !isFetchingList.value
    ? t('COOP_PRODUCERS.EMPTY_STATE.TITLE')
    : ''
);

const showProducer = producerId => {
  router.push({
    name: 'coop_producers_dashboard_show',
    params: { accountId: route.params.accountId, producerId },
  });
};

const openCreateDialog = () => {
  formDialogRef.value?.open();
};

const openEditDialog = producer => {
  formDialogRef.value?.open(producer);
};

const openDeleteDialog = producer => {
  deleteDialogRef.value?.open(producer);
};

const retryFetch = () => {
  producersStore.get();
};

onMounted(() => {
  producersStore.get();
});
</script>

<template>
  <div class="flex flex-col w-full h-full overflow-hidden bg-n-surface-1">
    <header
      class="flex items-center justify-between flex-shrink-0 gap-4 px-6 py-4 border-b border-n-weak"
    >
      <h1 class="text-xl font-medium text-n-slate-12">
        {{ t('COOP_PRODUCERS.HEADER') }}
      </h1>
      <Button
        v-if="canCreate"
        icon="i-lucide-plus"
        :label="t('COOP_PRODUCERS.ACTIONS.CREATE')"
        @click="openCreateDialog"
      />
    </header>

    <main class="flex-1 px-6 py-4 overflow-y-auto">
      <div class="w-full max-w-5xl mx-auto">
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
          v-else-if="fetchError"
          class="flex flex-col items-center justify-center gap-3 px-6 py-24 text-center rounded-2xl border border-n-weak bg-n-solid-2"
        >
          <Icon
            :icon="
              isPermissionError ? 'i-lucide-lock' : 'i-lucide-triangle-alert'
            "
            class="size-6 text-n-slate-10"
          />
          <span class="text-lg font-medium text-n-slate-12">
            {{
              isPermissionError
                ? t('COOP_PRODUCERS.ERROR_STATE.PERMISSION.TITLE')
                : t('COOP_PRODUCERS.ERROR_STATE.GENERIC.TITLE')
            }}
          </span>
          <p class="max-w-md text-sm text-n-slate-11">
            {{
              isPermissionError
                ? t('COOP_PRODUCERS.ERROR_STATE.PERMISSION.SUBTITLE')
                : t('COOP_PRODUCERS.ERROR_STATE.GENERIC.SUBTITLE')
            }}
          </p>
          <Button
            v-if="!isPermissionError"
            icon="i-lucide-refresh-cw"
            variant="faded"
            color="slate"
            :label="t('COOP_PRODUCERS.ERROR_STATE.RETRY')"
            @click="retryFetch"
          />
        </div>

        <div
          v-else-if="isFetchingList && !producers.length"
          class="flex flex-col items-center justify-center gap-3 py-24 text-n-slate-11"
        >
          <Spinner />
          <span class="text-sm">{{ t('COOP_PRODUCERS.LOADING') }}</span>
        </div>

        <BaseTable
          v-else
          :headers="tableHeaders"
          :items="producers"
          :no-data-message="noDataMessage"
          :loading="isFetchingList"
        >
          <template #row="{ items }">
            <BaseTableRow
              v-for="producer in items"
              :key="producer.id"
              :item="producer"
              class="cursor-pointer hover:bg-n-alpha-1"
              @click="showProducer(producer.id)"
            >
              <BaseTableCell>
                <div class="flex flex-col min-w-0 gap-0.5">
                  <span class="text-body-main text-n-slate-12 truncate">
                    {{ producer.businessName }}
                  </span>
                  <span
                    v-if="producer.tradeName"
                    class="text-body-main text-n-slate-11 truncate"
                  >
                    {{ producer.tradeName }}
                  </span>
                </div>
              </BaseTableCell>
              <BaseTableCell>
                <span class="text-body-main text-n-slate-12">
                  {{ producer.cuitFormatted || '—' }}
                </span>
              </BaseTableCell>
              <BaseTableCell>
                <span class="text-body-main text-n-slate-11">
                  {{ producerTypeLabel(producer.producerType) }}
                </span>
              </BaseTableCell>
              <BaseTableCell>
                <WootLabel
                  :label="statusLabel(producer.status)"
                  :color="producer.status === 'active' ? 'teal' : 'slate'"
                  compact
                />
              </BaseTableCell>
              <BaseTableCell>
                <span class="text-body-main text-n-slate-11">
                  {{ producer.primaryPhone || '—' }}
                </span>
              </BaseTableCell>
              <BaseTableCell align="end">
                <div class="flex justify-end gap-1" @click.stop>
                  <Button
                    v-tooltip.top="t('COOP_PRODUCERS.ACTIONS.EDIT')"
                    icon="i-lucide-pencil"
                    slate
                    sm
                    variant="ghost"
                    @click="openEditDialog(producer)"
                  />
                  <Button
                    v-tooltip.top="t('COOP_PRODUCERS.ACTIONS.DELETE')"
                    icon="i-lucide-trash-2"
                    slate
                    sm
                    variant="ghost"
                    class="hover:enabled:text-n-ruby-11 hover:enabled:bg-n-ruby-2"
                    @click="openDeleteDialog(producer)"
                  />
                </div>
              </BaseTableCell>
            </BaseTableRow>
          </template>
        </BaseTable>
      </div>
    </main>

    <ProducerFormDialog ref="formDialogRef" />
    <ConfirmProducerDeleteDialog ref="deleteDialogRef" />
  </div>
</template>
