# CoopFlow-owned permission vocabulary (design §7.1). Validated on
# CoopCore::StaffRole#permissions (inclusion), same shape as
# CustomRole::PERMISSIONS -- but CustomRole::PERMISSIONS is NEVER patched
# (R4, dual role systems are accepted and strictly non-overlapping):
# CustomRole governs Chatwoot inbox/conversation/contact; CoopCore::Permission
# governs CoopCore::* resources only.
module CoopCore::Permission
  ALL = %w[
    producers_read producers_manage
    fields_read fields_manage
    plots_read plots_manage
    crops_read crops_manage
    branches_read branches_manage
    staff_read staff_manage
    modules_read modules_manage
    audit_read
    export_data
  ].freeze
end
