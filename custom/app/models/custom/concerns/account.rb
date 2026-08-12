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
    # S6: coop_core_staff_role_assignments carries real, non-deferrable DB FKs
    # (ON DELETE CASCADE) to both coop_core_staff_profiles and
    # coop_core_staff_roles, so either destroy order is safe at the DB level.
    # Profiles are destroyed first purely so the app-level cascade
    # (CoopCore::StaffProfile#role_assignments dependent: :destroy) fires
    # audit callbacks on assignments before their role disappears underneath
    # them -- CoopCore::StaffRole#role_assignments carries the same
    # dependent: :destroy as a second, redundant safety net.
    has_many :coop_staff_profiles, class_name: 'CoopCore::StaffProfile', dependent: :destroy
    has_many :coop_staff_roles, class_name: 'CoopCore::StaffRole', dependent: :destroy
    # S7: coop_core_events/coop_core_event_subscriptions carry the same kind
    # of real, non-deferrable DB FK to accounts as every association above
    # -- dependent: :destroy (never :destroy_async), same lesson.
    has_many :coop_events, class_name: 'CoopCore::Event', dependent: :destroy
    has_many :coop_event_subscriptions, class_name: 'CoopCore::EventSubscription', dependent: :destroy
  end
end
