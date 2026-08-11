# Tenant-scope override for a module across the five per-tenant precedence
# tiers (design §5.2, tiers 1-5): user, beta_group, staff_role, branch,
# account. Read exclusively through CoopCore::Feature::Resolver -- enforced
# by spec/custom/feature_flag_boundary_spec.rb.
class CoopCore::ModuleSetting < CoopCore::ApplicationRecord
  include CoopCore::AccountScoped

  SCOPE_TYPES = %w[account branch staff_role beta_group user].freeze
  SCOPE_ID_TYPES = %w[branch staff_role user].freeze
  SCOPE_KEY_TYPES = %w[beta_group].freeze

  validates :module_key, presence: true
  validates :scope_type, presence: true, inclusion: { in: SCOPE_TYPES }
  validates :enabled, inclusion: { in: [true, false] }
  validates :scope_id, presence: true, if: -> { scope_type.in?(SCOPE_ID_TYPES) }
  validates :scope_key, presence: true, if: -> { scope_type.in?(SCOPE_KEY_TYPES) }
  # Mirrors the account-scope partial unique index (design §4) so a
  # concurrent-free duplicate write fails validation (422) instead of
  # reaching the DB and raising RecordNotUnique (500). The index remains the
  # real guarantee under concurrency -- see CoopCore::Feature.set_account_override.
  validates :module_key, uniqueness: { scope: :account_id, conditions: -> { where(scope_type: 'account') } },
                         if: -> { scope_type == 'account' }
  validate :scope_id_blank_unless_scope_id_type
  validate :scope_key_blank_unless_scope_key_type

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

  # Each scope_type owns exactly one of scope_id/scope_key (design §4); a
  # stray value from another scope's shape must not silently pass -- account
  # rows require both blank, branch/staff_role/user require scope_id only,
  # beta_group requires scope_key only.
  def scope_id_blank_unless_scope_id_type
    return if scope_type.in?(SCOPE_ID_TYPES)

    errors.add(:scope_id, 'must be blank for this scope type') if scope_id.present?
  end

  def scope_key_blank_unless_scope_key_type
    return if scope_type.in?(SCOPE_KEY_TYPES)

    errors.add(:scope_key, 'must be blank for this scope type') if scope_key.present?
  end
end
