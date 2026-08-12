# A field's plot (lote) -- design §4/Domain 4. Deliberately does not
# denormalize producer_id: account_id is the tenancy backstop, the producer
# is reachable via `field` (design §4 note: fewer invariants to keep in sync).
class CoopCore::Plot < CoopCore::ApplicationRecord
  include CoopCore::AccountScoped

  belongs_to :field, class_name: 'CoopCore::Field'
  # ON DELETE CASCADE at the DB level (migration 20260812100100) is the
  # backstop; dependent: :destroy runs the cascade synchronously.
  has_many :crops, class_name: 'CoopCore::Crop', dependent: :destroy

  validates :name, presence: true, uniqueness: { scope: :field_id, case_sensitive: false }
  validates :hectares, numericality: { greater_than: 0 }, allow_nil: true
  validate :account_matches_field

  private

  def account_matches_field
    return if field.blank? || account_id.blank?

    errors.add(:field, :invalid) if field.account_id != account_id
  end
end
