class CreateCoopCoreStaffRoleAssignments < ActiveRecord::Migration[7.1]
  def change
    create_table :coop_core_staff_role_assignments do |t|
      # accounts.id is `serial` (int4), never bigint -- see custom/README.md /
      # design R10. coop_core_staff_profiles.id, coop_core_staff_roles.id and
      # coop_core_branches.id are our own PKs (bigint, Rails default).
      t.integer :account_id, null: false
      t.bigint :staff_profile_id, null: false
      t.bigint :staff_role_id, null: false
      t.bigint :branch_id

      t.timestamps
    end

    add_staff_role_assignment_indexes
    add_staff_role_assignment_foreign_keys
  end

  private

  def add_staff_role_assignment_foreign_keys
    add_foreign_key :coop_core_staff_role_assignments, :accounts, column: :account_id
    # ON DELETE CASCADE: an assignment without its profile is meaningless.
    # CoopCore::StaffProfile#role_assignments also declares
    # dependent: :destroy so the app-level cascade runs synchronously and
    # fires audit callbacks before the DB FK ever has to act (same pattern as
    # Producer -> Field in S4b).
    add_foreign_key :coop_core_staff_role_assignments, :coop_core_staff_profiles, column: :staff_profile_id, on_delete: :cascade
    # ON DELETE CASCADE (deliberate choice, S6 design task): an assignment
    # without its role is equally meaningless -- unlike branch_id below, there
    # is no "cooperative-wide" fallback state for a missing role.
    # CoopCore::StaffRole#role_assignments also declares
    # dependent: :destroy for the same reason.
    add_foreign_key :coop_core_staff_role_assignments, :coop_core_staff_roles, column: :staff_role_id, on_delete: :cascade
    # ON DELETE CASCADE (review-fix, S6): NOT :nullify. Unlike producers/
    # fields, a NULL branch_id on an assignment is already a meaningful,
    # overloaded state -- "cooperative-wide by design". Nullifying the
    # branch_id on branch deletion collapsed a branch-scoped assignment into
    # that same state, silently WIDENING the profile's access from one
    # branch to the whole cooperative. Deleting a branch must instead revoke
    # the scoped assignment entirely. CoopCore::Branch#staff_role_assignments
    # also declares dependent: :destroy so the app-level cascade runs
    # synchronously (same pattern as Producer -> Field in S4b).
    add_foreign_key :coop_core_staff_role_assignments, :coop_core_branches, column: :branch_id, on_delete: :cascade
  end

  def add_staff_role_assignment_indexes
    add_index :coop_core_staff_role_assignments, %i[staff_profile_id staff_role_id],
              unique: true,
              where: 'branch_id IS NULL',
              name: 'index_coop_staff_role_assignments_on_profile_role_no_branch'
    add_index :coop_core_staff_role_assignments, %i[staff_profile_id staff_role_id branch_id],
              unique: true,
              where: 'branch_id IS NOT NULL',
              name: 'index_coop_staff_role_assignments_on_profile_role_branch'
    add_index :coop_core_staff_role_assignments, :staff_role_id
    add_index :coop_core_staff_role_assignments, :branch_id
    add_index :coop_core_staff_role_assignments, :account_id
  end
end
