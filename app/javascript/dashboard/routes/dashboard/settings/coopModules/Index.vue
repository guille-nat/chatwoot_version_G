<script setup>
import { computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';

import { useAlert } from 'dashboard/composables';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import SettingsLayout from '../SettingsLayout.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import { BaseTable } from 'dashboard/components-next/table';
import CoopModuleRow from 'dashboard/components-next/Coop/Modules/CoopModuleRow.vue';
import { useCoopModulesStore } from 'dashboard/stores/coopModules';

const { t } = useI18n();
const coopModulesStore = useCoopModulesStore();

const modules = computed(() => coopModulesStore.getModules);
const uiFlags = computed(() => coopModulesStore.getUIFlags);
const isFetchingList = computed(() => uiFlags.value.fetchingList);
const fetchError = computed(() => coopModulesStore.getFetchError);
const isPermissionError = computed(() => fetchError.value === 'permission');

const tableHeaders = computed(() => [
  t('COOP_MODULES.LIST.TABLE_HEADER.MODULE'),
  t('COOP_MODULES.LIST.TABLE_HEADER.TYPE'),
  t('COOP_MODULES.LIST.TABLE_HEADER.STATUS'),
  t('COOP_MODULES.LIST.TABLE_HEADER.ENABLED'),
]);

const moduleByKey = computed(() =>
  Object.fromEntries(modules.value.map(item => [item.key, item]))
);

// A module is dependency-blocked when at least one of its `dependsOn` keys
// resolves to an ENABLED false in the same payload. This is purely a
// display concern -- the server already applied the dependency cascade
// when it resolved `enabled`, this just explains *why* to the admin.
const blockingModuleNames = coopModule =>
  (coopModule.dependsOn || [])
    .filter(dependencyKey => !moduleByKey.value[dependencyKey]?.enabled)
    .map(
      dependencyKey => moduleByKey.value[dependencyKey]?.name || dependencyKey
    );

const isPending = key => coopModulesStore.isToggling(key);

const fetchModules = () => {
  coopModulesStore.fetch();
};

// After a successful PATCH, `resolved` can legitimately differ from what
// the admin asked for (dependency cascade, ENV kill switch, a
// higher-priority tier set elsewhere). The switch already renders the
// resolved truth -- this only adds the "why" on top of it.
const explainMismatch = (key, requested, resolved) => {
  if (requested === resolved) return null;

  if (requested && !resolved) {
    const blockers = blockingModuleNames(moduleByKey.value[key] || {});
    if (blockers.length) {
      return t('COOP_MODULES.TOGGLE.NOT_APPLIED_DEPENDENCY', {
        moduleName: moduleByKey.value[key]?.name || key,
        blockingNames: blockers.join(', '),
      });
    }
    return t('COOP_MODULES.TOGGLE.NOT_APPLIED_GENERIC', {
      moduleName: moduleByKey.value[key]?.name || key,
    });
  }

  return t('COOP_MODULES.TOGGLE.STILL_ENABLED_GENERIC', {
    moduleName: moduleByKey.value[key]?.name || key,
  });
};

const handleToggle = async ({ key, enabled }) => {
  try {
    const { requested, resolved } = await coopModulesStore.toggle(key, enabled);
    const explanation = explainMismatch(key, requested, resolved);
    if (explanation) useAlert(explanation);
  } catch (error) {
    useAlert(
      error.isPermissionError
        ? t('COOP_MODULES.TOGGLE.PERMISSION_ERROR')
        : t('COOP_MODULES.TOGGLE.ERROR')
    );
  }
};

onMounted(() => {
  fetchModules();
});
</script>

<template>
  <SettingsLayout
    :is-loading="isFetchingList && !modules.length"
    :loading-message="t('COOP_MODULES.LOADING')"
  >
    <template #header>
      <BaseSettingsHeader
        :title="t('COOP_MODULES.HEADER')"
        :description="t('COOP_MODULES.DESCRIPTION')"
      />
    </template>
    <template #body>
      <div
        v-if="fetchError"
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
              ? t('COOP_MODULES.ERROR_STATE.PERMISSION.TITLE')
              : t('COOP_MODULES.ERROR_STATE.GENERIC.TITLE')
          }}
        </span>
        <p class="max-w-md text-sm text-n-slate-11">
          {{
            isPermissionError
              ? t('COOP_MODULES.ERROR_STATE.PERMISSION.SUBTITLE')
              : t('COOP_MODULES.ERROR_STATE.GENERIC.SUBTITLE')
          }}
        </p>
        <Button
          v-if="!isPermissionError"
          icon="i-lucide-refresh-cw"
          variant="faded"
          color="slate"
          :label="t('COOP_MODULES.ERROR_STATE.RETRY')"
          @click="fetchModules"
        />
      </div>

      <div
        v-else-if="isFetchingList && !modules.length"
        class="flex flex-col items-center justify-center gap-3 py-24 text-n-slate-11"
      >
        <Spinner />
        <span class="text-sm">{{ t('COOP_MODULES.LOADING') }}</span>
      </div>

      <BaseTable v-else :headers="tableHeaders" :items="modules">
        <template #row="{ items }">
          <CoopModuleRow
            v-for="coopModule in items"
            :key="coopModule.key"
            :coop-module="coopModule"
            :blocking-module-names="blockingModuleNames(coopModule)"
            :pending="isPending(coopModule.key)"
            @toggle="handleToggle"
          />
        </template>
      </BaseTable>
    </template>
  </SettingsLayout>
</template>
