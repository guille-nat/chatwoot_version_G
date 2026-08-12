# 8-tier feature resolution (design §5.2): kill switch > user > beta group >
# staff role > branch > cooperative > installation default > code default.
# Fail-closed: an unknown module, a missing account, or a contradictory tier
# (multiple matching rows, at least one disabled) all resolve to false.
#
# beta_groups: / staff_role_ids: accept explicit values so tiers 2-3 are
# independently testable without a real CoopCore::StaffProfile row. When
# omitted (nil, the default), they are derived from the account's active
# staff profile for the given user (S6 -- CoopCore::StaffProfile#beta_groups /
# #staff_role_ids), with zero resolver code changes needed once that model
# landed -- see spec/custom/models/coop_core/feature/resolver_spec.rb.
class CoopCore::Feature::Resolver
  def initialize(account:, user: nil, branch: nil, beta_groups: nil, staff_role_ids: nil)
    @account = account
    @user = user
    @branch = branch
    @beta_groups = beta_groups
    @staff_role_ids = staff_role_ids
  end

  def enabled?(module_key)
    key = module_key.to_s
    resolved.key?(key) ? resolved[key] : resolved[key] = resolve(key)
  end

  def enabled_keys
    registry.keys.select { |key| enabled?(key) }
  end

  private

  attr_reader :account, :user, :branch

  def resolved
    @resolved ||= {}
  end

  def registry
    ::CoopCore::Feature::Registry
  end

  def beta_groups
    @beta_groups ||= derived_staff_profile&.beta_groups || []
  end

  def staff_role_ids
    @staff_role_ids ||= derived_staff_profile&.staff_role_ids || []
  end

  def derived_staff_profile
    return nil unless user && defined?(::CoopCore::StaffProfile)

    ::CoopCore::StaffProfile.active.find_by(account_id: account.id, user_id: user.id)
  end

  def resolve(key)
    return false if account.blank?
    return false if kill_switch?(key)

    definition = registry.find(key)
    return false unless tier_value(key, definition)
    return false if definition.depends_on.any? { |dependency_key| !enabled?(dependency_key) }

    true
  rescue ::CoopCore::Feature::UnknownModuleError
    false
  end

  def tier_value(key, definition)
    [
      tier_user(key),
      tier_beta_group(key),
      tier_staff_role(key),
      tier_branch(key),
      tier_account(key),
      tier_environment(key),
      definition.default_enabled?
    ].find { |value| !value.nil? }
  end

  def tier_user(key)
    tier_scoped(matching(key, 'user') { |setting| setting.scope_id == user&.id })
  end

  def tier_beta_group(key)
    tier_scoped(matching(key, 'beta_group') { |setting| beta_groups.include?(setting.scope_key) })
  end

  def tier_staff_role(key)
    tier_scoped(matching(key, 'staff_role') { |setting| staff_role_ids.include?(setting.scope_id) })
  end

  def tier_branch(key)
    tier_scoped(matching(key, 'branch') { |setting| setting.scope_id == branch&.id })
  end

  def tier_account(key)
    tier_scoped(matching(key, 'account') { true })
  end

  # Any explicit disable within a tier wins over any explicit enable (design
  # ADR-007) -- one uniform fail-closed rule for the tiers that can match
  # more than one row (a user can hold several roles or beta groups).
  def tier_scoped(rows)
    return nil if rows.empty?

    rows.none? { |row| !row.enabled }
  end

  def matching(key, scope_type, &)
    settings_for(key, scope_type).select(&)
  end

  def tier_environment(key)
    ::CoopCore::ModuleDefault.cached_all[key]
  end

  def settings_for(key, scope_type)
    settings[[key, scope_type]] || []
  end

  def settings
    @settings ||= ::CoopCore::ModuleSetting.cached_for_account(account.id).group_by do |setting|
      [setting.module_key, setting.scope_type]
    end
  end

  def kill_switch?(key)
    disabled_modules.include?(key)
  end

  def disabled_modules
    ENV.fetch('COOP_DISABLED_MODULES', '').split(',').map(&:strip)
  end
end
