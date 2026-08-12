# Headless marker, not an ActiveRecord model (no table, never persisted,
# deliberately NOT a CoopCore::ApplicationRecord subclass so
# spec/custom/invariants_spec.rb's tenant-model checks never see it). Exists
# purely so Api::V1::Accounts::Coop::AuditLogsController's
# `authorize(coop_resource_class)` resolves to CoopCore::AuditLogPolicy
# through the same naming convention every other Coop::BaseController
# subclass relies on (design §6.1) -- the actual audit data rendered by that
# controller comes from the existing Audited::Audit table (design §9), not
# from this class.
# rubocop:disable Lint/EmptyClass -- deliberately empty, see comment above.
class CoopCore::AuditLog
end
# rubocop:enable Lint/EmptyClass
