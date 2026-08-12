# A producer's field (campo) -- design §4/Domain 4. Owned by a producer;
# account_id is the tenancy backstop, but producer is the real parent for
# name-uniqueness and cascade-delete purposes.
class CoopCore::Field < CoopCore::ApplicationRecord
  include CoopCore::AccountScoped

  belongs_to :producer, class_name: 'CoopCore::Producer'
  belongs_to :branch, class_name: 'CoopCore::Branch', optional: true
  # ON DELETE CASCADE at the DB level (migration 20260812100000) is the
  # backstop; dependent: :destroy runs the cascade synchronously and fires
  # Plot callbacks/audit trail, same lesson as Producer#fields (design §4.1).
  has_many :plots, class_name: 'CoopCore::Plot', dependent: :destroy

  validates :name, presence: true, uniqueness: { scope: :producer_id, case_sensitive: false }
  validates :total_hectares, numericality: { greater_than: 0 }, allow_nil: true
  validate :account_matches_producer
  validate :account_matches_branch

  before_validation :normalize_external_ref
  before_validation :prepare_jsonb_attributes

  private

  def account_matches_producer
    return if producer.blank? || account_id.blank?

    errors.add(:producer, :invalid) if producer.account_id != account_id
  end

  def account_matches_branch
    return if branch.blank? || account_id.blank?

    errors.add(:branch, :invalid) if branch.account_id != account_id
  end

  # Without this, '' is a real value to a future partial unique index (it
  # only excludes NULL), same lesson as CoopCore::Producer#normalize_external_ref.
  def normalize_external_ref
    self.external_ref = nil if external_ref.blank?
  end

  def prepare_jsonb_attributes
    self.custom_attributes = {} unless custom_attributes.is_a?(Hash)
  end
end
