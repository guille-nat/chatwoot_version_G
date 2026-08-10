# Tenant-scope override for a module across the five per-tenant precedence
# tiers (design §5.2, tiers 1-5): user, beta_group, staff_role, branch,
# account. Read exclusively through CoopCore::Feature::Resolver -- enforced
# by spec/custom/feature_flag_boundary_spec.rb.
class CoopCore::ModuleSetting < CoopCore::ApplicationRecord
  include CoopCore::AccountScoped

  SCOPE_TYPES = %w[account branch staff_role beta_group user].freeze
  SCOPE_ID_TYPES = %w[branch staff_role user].freeze

  validates :module_key, presence: true
  validates :scope_type, presence: true, inclusion: { in: SCOPE_TYPES }
  validates :enabled, inclusion: { in: [true, false] }
  validates :scope_id, presence: true, if: -> { scope_type.in?(SCOPE_ID_TYPES) }
  validates :scope_key, presence: true, if: -> { scope_type == 'beta_group' }
  validate :scope_extras_blank_for_account_scope

  after_commit :expire_cache

  class << self
    def cache_key(account_id)
      "coop_core/v1/accounts/#{account_id}/module_settings"
    end

    def cached_for_account(account_id)
      Rails.cache.fetch(cache_key(account_id), expires_in: 5.minutes) { where(account_id: account_id).to_a }
    end
  end

  private

  def expire_cache
    Rails.cache.delete(self.class.cache_key(account_id))
  end

  def scope_extras_blank_for_account_scope
    return unless scope_type == 'account'

    errors.add(:scope_id, 'must be blank for account scope') if scope_id.present?
    errors.add(:scope_key, 'must be blank for account scope') if scope_key.present?
  end
end
