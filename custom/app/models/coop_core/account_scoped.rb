# Shared concern for every tenant-scoped CoopCore model. Guarantees the
# account_id column is present and required -- the DB layer of the tenancy
# defense-in-depth described in design §10.3.
module CoopCore::AccountScoped
  extend ActiveSupport::Concern

  included do
    belongs_to :account
    audited associated_with: :account

    validates :account_id, presence: true
  end
end
