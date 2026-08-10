class CreateCoopCoreCooperativeProfiles < ActiveRecord::Migration[7.1]
  def change
    create_table :coop_core_cooperative_profiles do |t|
      # accounts.id is `serial` (int4), never bigint -- see custom/README.md.
      t.integer :account_id, null: false
      t.string :legal_name
      t.string :cuit, limit: 11
      t.string :locale, null: false, default: 'es-AR'
      t.string :timezone, null: false, default: 'America/Argentina/Buenos_Aires'
      t.string :currency, null: false, default: 'ARS'
      t.jsonb :branding, null: false, default: {}
      t.jsonb :settings, null: false, default: {}

      t.timestamps
    end

    add_index :coop_core_cooperative_profiles, :account_id, unique: true
    add_foreign_key :coop_core_cooperative_profiles, :accounts, column: :account_id
  end
end
