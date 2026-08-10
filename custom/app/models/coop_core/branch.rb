# A cooperative's branch/sucursal (design §4). Org node used as the branch
# scope for feature flags (S3) and staff role assignments (S6).
class CoopCore::Branch < CoopCore::ApplicationRecord
  include CoopCore::AccountScoped

  KINDS = %w[branch plant silo office].freeze

  validates :name, presence: true
  validates :kind, presence: true, inclusion: { in: KINDS }
  validates :timezone, presence: true
  validates :code, uniqueness: { scope: :account_id, case_sensitive: false }, allow_nil: true

  before_validation :prepare_jsonb_attributes

  scope :active, -> { where(active: true) }

  private

  def prepare_jsonb_attributes
    self.settings = {} unless settings.is_a?(Hash)
  end
end
