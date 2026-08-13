# Module registry + flag operator surface (design §5.3, §12#5): GET lists
# every registered module with its ACCOUNT-CANONICAL resolved state (tiers
# above account -- user/beta_group/staff_role/branch -- are deliberately
# excluded here, see #coop_features below); PATCH toggles the account-scope
# override for one module. coop_module stays false -- the registry/gate
# infrastructure can never be gated behind itself.
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

  # Overrides CoopCore::ModuleGated#coop_features: this endpoint reads and
  # writes the COOPERATIVE's own state, not the acting admin's resolved
  # view. The base concern folds in user/beta_group/staff_role/branch
  # context (resolver.rb tier_value, tiers 2-5), any of which can shadow the
  # account tier (tier 6) that #update writes -- an admin with a personal,
  # beta-group, or staff-role override would otherwise see (and silently
  # have shadowed) their own view instead of the account's. Resolving with
  # no user/branch context here limits resolution to the account tier and
  # below (installation default, code default), which is exactly the
  # cooperative-wide state this screen manages.
  #
  # Safe to override class-wide: coop_module = false makes ModuleGated's
  # before_action return before it ever calls #coop_features, so this only
  # changes what #index / #update assign to @features.
  def coop_features
    @coop_features ||= ::CoopCore::Feature.for(account: Current.account)
  end

  # There is no single per-request "record" to look up by :id here -- a
  # module's account-scope setting is a find-or-create keyed on (account,
  # module_key), not a member resource -- so this overrides the base
  # controller's id-based member/collection split entirely.
  #
  # Constraint: this always authorizes the class, never an instance. That is
  # safe for index/update today, but a future member action (e.g. show) that
  # relies on this override would hit CoopCore::BasePolicy#show? with a Class
  # as `record`, and `record.id` would raise NoMethodError. Any such action
  # must resolve and pass a real ModuleSetting instance instead of relying on
  # this method.
  def authorize_coop_resource
    authorize(coop_resource_class)
  end

  def render_module_not_found
    render_not_found_error('CoopFlow module could not be found')
  end
end
