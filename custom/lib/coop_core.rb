module CoopCore
  # Raised by CoopCore::BasePolicy::Scope#resolve when a query is attempted
  # without a tenant (Current.account) in context. A CoopCore query must never
  # run unscoped -- see design §7.4 / R5.
  class MissingAccountContext < StandardError; end

  def self.table_name_prefix
    'coop_core_'
  end
end
