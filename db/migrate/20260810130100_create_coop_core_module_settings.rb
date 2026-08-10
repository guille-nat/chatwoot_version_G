class CreateCoopCoreModuleSettings < ActiveRecord::Migration[7.1]
  def change
    create_table :coop_core_module_settings do |t|
      # accounts.id / users.id are `serial` (int4), never bigint -- see
      # custom/README.md. scope_id stays bigint: it references CoopFlow's own
      # PKs (coop_core_branches.id, coop_core_staff_roles.id), not a Chatwoot table.
      t.integer :account_id, null: false
      t.string :module_key, null: false
      t.string :scope_type, null: false
      t.bigint :scope_id
      t.string :scope_key
      t.boolean :enabled, null: false, default: false
      t.integer :updated_by_id

      t.timestamps
    end

    add_module_setting_indexes
    add_foreign_key :coop_core_module_settings, :accounts, column: :account_id
    add_foreign_key :coop_core_module_settings, :users, column: :updated_by_id
  end

  private

  def add_module_setting_indexes
    add_index :coop_core_module_settings, :account_id

    # Three partial unique indexes (design §4): a plain composite unique
    # index would let NULL scope_id/scope_key rows duplicate freely, since
    # PostgreSQL treats NULLs as distinct.
    add_index :coop_core_module_settings, %i[account_id module_key],
              unique: true,
              where: "scope_type = 'account'",
              name: 'index_coop_core_module_settings_on_account_scope'
    add_index :coop_core_module_settings, %i[account_id module_key scope_type scope_id],
              unique: true,
              where: 'scope_id IS NOT NULL',
              name: 'index_coop_core_module_settings_on_scope_id'
    add_index :coop_core_module_settings, %i[account_id module_key scope_key],
              unique: true,
              where: 'scope_key IS NOT NULL',
              name: 'index_coop_core_module_settings_on_scope_key'
  end
end
