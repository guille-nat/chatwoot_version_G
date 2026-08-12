# A plot's crop (cultivo) -- design §4/Domain 4. `campaign` is a plain string
# (e.g. "2025/26"), not a table -- promoting it later is purely additive
# (design §4 note). species/status are code-declared lists, not PG enums, so
# extending them never needs a migration -- just a PR (design §4 note).
class CoopCore::Crop < CoopCore::ApplicationRecord
  include CoopCore::AccountScoped

  SPECIES = %w[soja maiz trigo girasol sorgo cebada].freeze
  STATUSES = %w[planned sown growing harvested cancelled].freeze
  CAMPAIGN_FORMAT = %r{\A\d{4}/\d{2}\z}

  belongs_to :plot, class_name: 'CoopCore::Plot'

  validates :species, presence: true, inclusion: { in: SPECIES }
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :campaign, presence: true, format: { with: CAMPAIGN_FORMAT }
  validates :hectares, numericality: { greater_than: 0 }, allow_nil: true
  validates :expected_yield_kg_per_ha, numericality: { greater_than: 0 }, allow_nil: true
  validate :account_matches_plot

  private

  def account_matches_plot
    return if plot.blank? || account_id.blank?

    errors.add(:plot, :invalid) if plot.account_id != account_id
  end
end
