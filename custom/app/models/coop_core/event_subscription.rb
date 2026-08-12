# A cooperative's outbound event subscription (design §8.5/§9). Reuses the
# existing core `WebhookSecretable` concern (app/models/concerns/
# webhook_secretable.rb) for `secret` -- `has_secure_token :secret`
# auto-generates a random token when the caller doesn't supply one, and
# `encrypts :secret if Chatwoot.encryption_configured?` matches the exact
# convention already used by the core `Webhook`, `Channel::Email`,
# `Integrations::Hook`, etc models. No new encryption wiring needed: this
# app already configures ActiveRecord::Encryption (config/application.rb,
# `Chatwoot.encryption_configured?`), CoopFlow just consumes it.
class CoopCore::EventSubscription < CoopCore::ApplicationRecord
  include WebhookSecretable

  # `Audited::Auditor::ClassMethods#audited` silently no-ops on a second call
  # (its "don't allow multiple calls" guard: `return if
  # included_modules.include?(Audited::Auditor::AuditedInstanceMethods)`) --
  # once CoopCore::AccountScoped#included runs its own
  # `audited associated_with: :account` below, any later `audited` call
  # would be completely ignored. Declaring the FULL set of options --
  # including the `except: [:secret]` design §9 requires so the plaintext
  # secret is never written to the audits table -- BEFORE `include
  # CoopCore::AccountScoped` makes THIS the first (and only effective) call.
  # AccountScoped's own `audited associated_with: :account` then hits the
  # guard and is a genuine no-op; `associated_with: :account` is still
  # correctly set because this call already set it.
  audited associated_with: :account, except: [:secret]

  include CoopCore::AccountScoped

  validates :url, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]) }

  before_validation :normalize_event_keys

  scope :active, -> { where(active: true) }
  # "active AND (event_keys empty OR event_keys includes key)" matching rule
  # (S7 task doc / design §8.5): an empty event_keys list means "subscribed
  # to every CoopFlow event key", matching the same "empty = unrestricted"
  # convention CoopCore::BasePolicy::Scope uses for NULL branch_id.
  scope :matching, ->(key) { where("event_keys = '{}' OR ? = ANY(event_keys)", key.to_s) }

  private

  # Free-form event_keys (S7 task doc: "validate non-empty strings and
  # document" was the fallback option, chosen over a hardcoded inclusion
  # list) -- normalize instead of reject, matching the existing
  # StaffRole#prepare_permissions / StaffProfile#prepare_beta_groups
  # convention for array-ish attributes in this codebase. A closed list
  # would need a code change (and a deploy) every time a later F-phase adds
  # a new event key, which fights the modular/no-deploy-for-config
  # philosophy this whole slice is built on (CLAUDE.md "Módulos").
  def normalize_event_keys
    self.event_keys = Array(event_keys).map { |key| key.to_s.strip }.reject(&:blank?).uniq
  end
end
