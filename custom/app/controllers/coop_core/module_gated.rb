# Controller concern that wires the real module gate (design §6.1, S3.8)
# into every Api::V1::Accounts::Coop::* controller. coop_module = false marks
# a core-platform resource (e.g. branches) that is never gated -- it is
# checked first and short-circuits before ever touching the registry, so a
# non-licensable resource never needs a coop_modules.yml entry.
module CoopCore::ModuleGated
  extend ActiveSupport::Concern

  included do
    before_action :ensure_coop_module_enabled!
  end

  private

  def ensure_coop_module_enabled!
    return if coop_module == false
    return if coop_features.enabled?(coop_module)

    render json: {
      error: I18n.t('coop_core.errors.module_disabled'),
      error_code: 'module_disabled',
      module: coop_module
    }, status: :forbidden
  end

  def coop_features
    @coop_features ||= ::CoopCore::Feature.for(account: Current.account, user: Current.user, branch: current_branch)
  end

  # No staff profile / default-branch mechanism exists yet (S6). A caller
  # that wants branch-scoped resolution today passes ?branch_id= explicitly;
  # an unknown or foreign branch_id simply resolves to no branch context
  # (find_by, not find!) rather than raising.
  def current_branch
    return nil if params[:branch_id].blank?

    @current_branch ||= Current.account.coop_branches.find_by(id: params[:branch_id])
  end
end
