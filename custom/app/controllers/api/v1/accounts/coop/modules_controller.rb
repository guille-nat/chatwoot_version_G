# Module registry + flag operator surface (design §5.3, §12#5): GET lists
# every registered module with its resolved state for the current account;
# PATCH toggles the account-scope override for one module. coop_module stays
# false -- the registry/gate infrastructure can never be gated behind itself.
class Api::V1::Accounts::Coop::ModulesController < Api::V1::Accounts::Coop::BaseController
  self.coop_module = false
  self.coop_resource_class = ::CoopCore::ModuleSetting

  rescue_from CoopCore::Feature::UnknownModuleError, with: :render_module_not_found

  def index
    @modules = ::CoopCore::Feature::Registry.modules
    @features = coop_features
  end

  def update
    ::CoopCore::Feature.set_account_override(
      params[:key],
      account: Current.account,
      enabled: ActiveModel::Type::Boolean.new.cast(params[:enabled]),
      updated_by: Current.user
    )

    @modules = ::CoopCore::Feature::Registry.modules
    @features = coop_features
  end

  private

  # There is no single per-request "record" to look up by :id here -- a
  # module's account-scope setting is a find-or-create keyed on (account,
  # module_key), not a member resource -- so this overrides the base
  # controller's id-based member/collection split entirely.
  def authorize_coop_resource
    authorize(coop_resource_class)
  end

  def render_module_not_found
    render_not_found_error('CoopFlow module could not be found')
  end
end
