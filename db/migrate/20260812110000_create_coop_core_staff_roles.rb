class CreateCoopCoreStaffRoles < ActiveRecord::Migration[7.1]
  def change
    create_table :coop_core_staff_roles do |t|
      # accounts.id is `serial` (int4), never bigint -- see custom/README.md /
      # design R10.
      t.integer :account_id, null: false
      t.string :key, null: false
      t.string :name, null: false
      t.text :description
      t.text :permissions, null: false, default: [], array: true
      t.boolean :system, null: false, default: false

      t.timestamps
    end

    add_staff_role_indexes
    add_foreign_key :coop_core_staff_roles, :accounts, column: :account_id
  end

  private

  def add_staff_role_indexes
    add_index :coop_core_staff_roles, %i[account_id key], unique: true
    add_index :coop_core_staff_roles, :permissions, using: :gin
  end
end
