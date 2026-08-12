# Read-only audit trail for CoopCore::* changes (design §9/R6). CoopFlow
# rows already land in the shared `audits` table (Enterprise::AuditLog) via
# every CoopCore::AccountScoped model's `audited associated_with: :account`
# -- zero new audit infrastructure here, only a filtered, paginated read.
# Core platform surface (audit_read is a CoopFlow permission, not a
# licensable module) -- coop_module stays false, same as
# branches/staff_roles/modules.
class Api::V1::Accounts::Coop::AuditLogsController < Api::V1::Accounts::Coop::BaseController
  self.coop_module = false
  self.coop_resource_class = ::CoopCore::AuditLog

  DEFAULT_PER_PAGE = 25
  MAX_PER_PAGE = 100

  def index
    @audit_logs = coop_core_audits.page(params[:page]).per(per_page)
    @current_page = @audit_logs.current_page
    @total_entries = @audit_logs.total_count
    @per_page = per_page
  end

  private

  # `auditable_type LIKE 'CoopCore::%'` (design §9) is the CoopFlow-owned
  # slice of the account's full audit trail -- everything else in
  # `associated_audits` belongs to Chatwoot core/enterprise models and is
  # already served by the existing (premium-flag-gated)
  # Api::V1::Accounts::AuditLogsController.
  def coop_core_audits
    Current.account.associated_audits
           .where("auditable_type LIKE 'CoopCore::%'")
           .order(created_at: :desc)
  end

  def per_page
    requested = params[:per_page].presence&.to_i
    return DEFAULT_PER_PAGE if requested.blank? || requested <= 0

    [requested, MAX_PER_PAGE].min
  end
end
