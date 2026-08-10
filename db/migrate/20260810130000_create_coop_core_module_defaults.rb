class CreateCoopCoreModuleDefaults < ActiveRecord::Migration[7.1]
  def change
    create_table :coop_core_module_defaults do |t|
      t.string :module_key, null: false
      t.boolean :enabled, null: false, default: false
      # users.id is `serial` (int4), never bigint -- see custom/README.md.
      t.integer :updated_by_id

      t.timestamps
    end

    add_index :coop_core_module_defaults, :module_key, unique: true
    add_foreign_key :coop_core_module_defaults, :users, column: :updated_by_id
  end
end
