class CreateCoopCoreBranches < ActiveRecord::Migration[7.1]
  def change
    create_table :coop_core_branches do |t|
      # accounts.id is `serial` (int4), never bigint -- see custom/README.md.
      t.integer :account_id, null: false
      t.string :name, null: false
      t.string :code
      t.string :kind, null: false, default: 'branch'
      t.string :address_line
      t.string :city
      t.string :province
      t.string :postal_code
      t.decimal :latitude, precision: 10, scale: 6
      t.decimal :longitude, precision: 10, scale: 6
      t.string :timezone, null: false, default: 'America/Argentina/Buenos_Aires'
      t.boolean :active, null: false, default: true
      t.jsonb :settings, null: false, default: {}

      t.timestamps
    end

    add_branch_indexes
    add_foreign_key :coop_core_branches, :accounts, column: :account_id
  end

  private

  def add_branch_indexes
    add_index :coop_core_branches, %i[account_id active]
    add_index :coop_core_branches, 'account_id, lower(code)',
              unique: true,
              where: 'code IS NOT NULL',
              name: 'index_coop_core_branches_on_account_id_and_lower_code'
  end
end
