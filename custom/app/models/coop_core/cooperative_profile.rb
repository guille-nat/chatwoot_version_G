# Per-account cooperative identity/settings (design §4). One profile per
# account -- enforced by a unique index on account_id plus the model
# validation below.
class CoopCore::CooperativeProfile < CoopCore::ApplicationRecord
  include CoopCore::AccountScoped

  # Basic shape check only -- full mod-11 CUIT validation is
  # CoopCore::Producer::Cuit's job (S4a), not duplicated here.
  CUIT_FORMAT = /\A\d{11}\z/

  validates :legal_name, presence: true
  validates :account_id, uniqueness: true
  validates :cuit, format: { with: CUIT_FORMAT }, allow_nil: true
end
