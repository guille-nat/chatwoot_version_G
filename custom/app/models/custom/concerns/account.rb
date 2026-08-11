# Auto-included into ::Account by the existing Account.include_mod_with('Concerns::Account')
# call (app/models/account.rb) -- zero core edits required (design D4).
module Custom::Concerns::Account
  extend ActiveSupport::Concern

  included do
    # coop_core_producers/branches/cooperative_profiles/module_settings all
    # carry a real, non-deferrable DB foreign key to accounts (db/schema.rb).
    # Those FKs are enforced inside the same transaction as
    # `DELETE FROM accounts`, but :destroy_async enqueues the child destroy
    # job for AFTER commit -- too late to satisfy the FK, so it raises
    # ActiveRecord::InvalidForeignKey and blocks account destruction the
    # moment any of these tables has a row (verified against
    # activerecord-7.1.5.2; the :destroy_async precedent this file used to
    # claim from other has_many associations doesn't hold here because none
    # of Chatwoot's native associations have a DB FK to accounts). Children
    # must be destroyed synchronously, and producers before branches --
    # coop_core_producers.branch_id also FKs to coop_core_branches, so a
    # producer row would otherwise block branch deletion (the branch_id FK
    # is on_delete: :nullify as a backstop, but destroy order shouldn't
    # depend on it).
    has_many :coop_producers, class_name: 'CoopCore::Producer', dependent: :destroy
    has_one :coop_cooperative_profile, class_name: 'CoopCore::CooperativeProfile', dependent: :destroy
    has_many :coop_branches, class_name: 'CoopCore::Branch', dependent: :destroy
    has_many :coop_module_settings, class_name: 'CoopCore::ModuleSetting', dependent: :destroy
  end
end
