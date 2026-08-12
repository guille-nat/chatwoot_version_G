class CreateCoopCoreStaffProfiles < ActiveRecord::Migration[7.1]
  def change
    create_table :coop_core_staff_profiles do |t|
      # accounts.id and users.id are `serial` (int4), never bigint -- see
      # custom/README.md / design R10. coop_core_branches.id is our own PK
      # (bigint, Rails default), so default_branch_id stays bigint.
      t.integer :account_id, null: false
      t.integer :user_id, null: false
      t.bigint :default_branch_id
      t.text :beta_groups, null: false, default: [], array: true
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_staff_profile_indexes
    add_staff_profile_foreign_keys
  end

  private

  def add_staff_profile_foreign_keys
    add_foreign_key :coop_core_staff_profiles, :accounts, column: :account_id
    # ON DELETE CASCADE: a staff profile has no meaning once its user is gone
    # (design §4 -- "user_id ... FK->users cascade").
    add_foreign_key :coop_core_staff_profiles, :users, column: :user_id, on_delete: :cascade
    # ON DELETE SET NULL: mirrors coop_core_producers.branch_id -- deleting a
    # branch must unassign it as anyone's default branch, never block or
    # cascade-delete the profile.
    add_foreign_key :coop_core_staff_profiles, :coop_core_branches, column: :default_branch_id, on_delete: :nullify
  end

  def add_staff_profile_indexes
    add_index :coop_core_staff_profiles, %i[account_id user_id], unique: true
    add_index :coop_core_staff_profiles, :default_branch_id
    add_index :coop_core_staff_profiles, :beta_groups, using: :gin
  end
end
