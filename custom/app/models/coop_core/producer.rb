# A cooperative's producer (productor asociado) -- design §4/Domain 3.
# Contact linking (auto-match by phone/CUIT, S5) lives in ContactLinkable;
# `contact_id` is still not writable through producer create/update -- see
# ProducersController -- it's only ever set via ContactLinkable's
# link_contact/unlink_contact (manual, ContactLinksController) or
# auto_link_contact (automatic, CoopCore::LinkProducerJob).
class CoopCore::Producer < CoopCore::ApplicationRecord
  include CoopCore::AccountScoped
  include ContactLinkable

  PRODUCER_TYPES = %w[individual company].freeze
  STATUSES = %w[active inactive].freeze

  belongs_to :branch, class_name: 'CoopCore::Branch', optional: true
  belongs_to :contact, optional: true
  # ON DELETE CASCADE at the DB level (migration 20260812100000) is the
  # backstop; dependent: :destroy runs the cascade synchronously and fires
  # Field callbacks/audit trail -- same lesson as the S4a review-fix on
  # Custom::Concerns::Account (see custom/app/models/custom/concerns/account.rb).
  has_many :fields, class_name: 'CoopCore::Field', dependent: :destroy

  validates :business_name, presence: true
  validates :producer_type, presence: true, inclusion: { in: PRODUCER_TYPES }
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :cuit, uniqueness: { scope: :account_id }, allow_nil: true
  validates :external_ref, uniqueness: { scope: :account_id }, allow_nil: true
  validate :cuit_must_be_valid
  validate :account_matches_branch
  validate :account_matches_contact

  before_validation :normalize_cuit
  before_validation :normalize_external_ref
  before_validation :prepare_jsonb_attributes

  def cuit_formatted
    return nil if cuit.blank?

    Cuit.format(cuit)
  end

  private

  def normalize_cuit
    self.cuit = cuit.present? ? Cuit.normalize(cuit) : nil
  end

  # Without this, '' is a real value to the partial unique index (it only
  # excludes NULL), so two producers could both save with external_ref: ''.
  def normalize_external_ref
    self.external_ref = nil if external_ref.blank?
  end

  def cuit_must_be_valid
    return if cuit.blank?

    errors.add(:cuit, :invalid) unless Cuit.valid?(cuit)
  end

  def account_matches_branch
    return if branch.blank? || account_id.blank?

    errors.add(:branch, :invalid) if branch.account_id != account_id
  end

  def account_matches_contact
    return if contact.blank? || account_id.blank?

    errors.add(:contact, :invalid) if contact.account_id != account_id
  end

  def prepare_jsonb_attributes
    self.custom_attributes = {} unless custom_attributes.is_a?(Hash)
  end
end
