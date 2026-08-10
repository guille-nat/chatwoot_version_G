# Public API for CoopFlow module/feature resolution (design §5.3). Nothing
# outside CoopCore::Feature::{Resolver,Registry} may reference ModuleSetting
# or ModuleDefault directly -- enforced by
# spec/custom/feature_flag_boundary_spec.rb.
module CoopCore::Feature
  class UnknownModuleError < StandardError; end
  class CyclicDependencyError < StandardError; end

  class << self
    # One-off check: CoopCore::Feature.enabled?(:market, account:, user:, branch:)
    def enabled?(module_key, account:, user: nil, branch: nil)
      # `for` is a Ruby keyword -- must call with an explicit receiver here,
      # otherwise the parser reads it as a `for..in` loop.
      self.for(account: account, user: user, branch: branch).enabled?(module_key)
    end

    # Memoized resolver for checking multiple keys against the same context:
    #   features = CoopCore::Feature.for(account:, user:, branch:)
    #   features.enabled?(:market)
    #   features.enabled_keys # drives the dynamic dashboard menu
    def for(account:, user: nil, branch: nil)
      ::CoopCore::Feature::Resolver.new(account: account, user: user, branch: branch)
    end
  end
end
