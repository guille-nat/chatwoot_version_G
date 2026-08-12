class CreateCoopCorePlots < ActiveRecord::Migration[7.1]
  def change
    create_table :coop_core_plots do |t|
      # accounts.id is `serial` (int4), never bigint -- see custom/README.md.
      # coop_core_fields.id is our own PK (bigint, Rails default).
      t.integer :account_id, null: false
      t.bigint :field_id, null: false
      t.string :name, null: false
      t.decimal :hectares, precision: 12, scale: 2
      # Plain jsonb GeoJSON polygon, no PostGIS (design §4 note).
      t.jsonb :geometry
      t.string :soil_type

      t.timestamps
    end

    add_plot_indexes
    add_foreign_key :coop_core_plots, :accounts, column: :account_id
    # ON DELETE CASCADE: a field's plots are owned by the field and have no
    # life of their own. CoopCore::Field#plots also declares
    # dependent: :destroy so the app-level cascade runs synchronously.
    add_foreign_key :coop_core_plots, :coop_core_fields, column: :field_id, on_delete: :cascade
  end

  private

  def add_plot_indexes
    add_index :coop_core_plots, %i[account_id field_id]
    add_index :coop_core_plots, 'field_id, lower(name)',
              unique: true,
              name: 'index_coop_core_plots_on_field_id_and_lower_name'
  end
end
