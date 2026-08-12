class CreateCoopCoreCrops < ActiveRecord::Migration[7.1]
  def change
    create_table :coop_core_crops do |t|
      # accounts.id is `serial` (int4), never bigint -- see custom/README.md.
      # coop_core_plots.id is our own PK (bigint, Rails default).
      t.integer :account_id, null: false
      t.bigint :plot_id, null: false
      t.string :species, null: false
      t.string :variety
      # campaign is a string (e.g. "2025/26"), not a table -- design §4 note.
      t.string :campaign, null: false
      t.date :sowing_date
      t.date :harvest_date
      t.decimal :hectares, precision: 12, scale: 2
      t.decimal :expected_yield_kg_per_ha, precision: 12, scale: 2
      t.string :status, null: false, default: 'planned'

      t.timestamps
    end

    add_crop_indexes
    add_foreign_key :coop_core_crops, :accounts, column: :account_id
    # ON DELETE CASCADE: a plot's crops are owned by the plot and have no life
    # of their own. CoopCore::Plot#crops also declares dependent: :destroy so
    # the app-level cascade runs synchronously.
    add_foreign_key :coop_core_crops, :coop_core_plots, column: :plot_id, on_delete: :cascade
  end

  private

  def add_crop_indexes
    add_index :coop_core_crops, %i[account_id campaign]
    add_index :coop_core_crops, %i[plot_id campaign]
    add_index :coop_core_crops, %i[account_id species]
  end
end
