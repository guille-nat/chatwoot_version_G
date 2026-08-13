<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import Switch from 'dashboard/components-next/switch/Switch.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import WootLabel from 'dashboard/components-next/label/Label.vue';
import { BaseTableRow, BaseTableCell } from 'dashboard/components-next/table';

const props = defineProps({
  coopModule: {
    type: Object,
    required: true,
  },
  // Names (not keys) of modules that must be enabled before this one can
  // resolve true, computed by the parent from `dependsOn` + the sibling
  // rows' resolved state in the same payload.
  blockingModuleNames: {
    type: Array,
    default: () => [],
  },
  pending: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['toggle']);

const { t } = useI18n();

const isBlocked = computed(() => props.blockingModuleNames.length > 0);
const isDisabled = computed(() => props.pending || isBlocked.value);

const blockedReason = computed(() =>
  t('COOP_MODULES.DEPENDENCY.REQUIRES', {
    moduleNames: props.blockingModuleNames.join(', '),
  })
);

// Mirrors the v-model + computed setter pattern used by
// AutomationRuleRow.vue / FeatureToggle.vue: the switch never owns state
// locally, it always reflects `coopModule.enabled` (sourced from the
// store's last server response) and only requests a change upstream.
const enabledModel = computed({
  get: () => props.coopModule.enabled,
  set: requestedEnabled => {
    emit('toggle', { key: props.coopModule.key, enabled: requestedEnabled });
  },
});
</script>

<template>
  <BaseTableRow :item="coopModule">
    <template #default>
      <BaseTableCell class="max-w-0 w-full">
        <div class="flex flex-col min-w-0 gap-0.5">
          <span class="text-body-main text-n-slate-12 truncate">
            {{ coopModule.name }}
          </span>
          <span class="text-body-main text-n-slate-11 truncate">
            {{ coopModule.description }}
          </span>
        </div>
      </BaseTableCell>

      <BaseTableCell>
        <WootLabel
          :label="
            coopModule.licensable
              ? t('COOP_MODULES.BADGE.LICENSABLE')
              : t('COOP_MODULES.BADGE.CORE')
          "
          :color="coopModule.licensable ? 'iris' : 'slate'"
          compact
        />
      </BaseTableCell>

      <BaseTableCell>
        <WootLabel
          :label="
            coopModule.enabled
              ? t('COOP_MODULES.STATUS.ENABLED')
              : t('COOP_MODULES.STATUS.DISABLED')
          "
          :color="coopModule.enabled ? 'teal' : 'slate'"
          compact
        />
      </BaseTableCell>

      <BaseTableCell align="end">
        <div class="flex flex-col items-end gap-1">
          <div class="flex items-center gap-2">
            <Spinner v-if="pending" :size="14" />
            <Switch v-model="enabledModel" :disabled="isDisabled" />
          </div>
          <span
            v-if="isBlocked"
            class="text-label-small text-n-slate-11 whitespace-nowrap"
          >
            {{ blockedReason }}
          </span>
        </div>
      </BaseTableCell>
    </template>
  </BaseTableRow>
</template>
