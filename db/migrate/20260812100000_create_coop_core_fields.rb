class CreateCoopCoreFields < ActiveRecord::Migration[7.1]
  def change
    create_table :coop_core_fields do |t|
      # accounts.id is `serial` (int4), never bigint -- see custom/README.md /
      # design R10. coop_core_producers.id and coop_core_branches.id are our
      # own PKs (bigint, Rails default), so producer_id/branch_id stay bigint.
      t.integer :account_id, null: false
      t.bigint :producer_id, null: false
      t.bigint :branch_id
      t.string :name, null: false
      t.decimal :total_hectares, precision: 12, scale: 2
      t.string :province
      t.string :locality
      t.decimal :latitude, precision: 10, scale: 6
      t.decimal :longitude, precision: 10, scale: 6
      t.string :external_ref
      t.jsonb :custom_attributes, null: false, default: {}

      t.timestamps
    end

    add_field_indexes
    add_field_foreign_keys
  end

  private

  def add_field_foreign_keys
    add_foreign_key :coop_core_fields, :accounts, column: :account_id
    # ON DELETE CASCADE: a producer's fields are owned by the producer and
    # have no life of their own (design §4). CoopCore::Producer#fields also
    # declares dependent: :destroy so the app-level cascade runs synchronously
    # and fires model callbacks/audit trail before the DB FK ever has to act.
    add_foreign_key :coop_core_fields, :coop_core_producers, column: :producer_id, on_delete: :cascade
    # ON DELETE SET NULL: mirrors coop_core_producers.branch_id -- deleting a
    # branch must unassign its fields, never block or cascade-delete them.
    add_foreign_key :coop_core_fields, :coop_core_branches, column: :branch_id, on_delete: :nullify
  end

  def add_field_indexes
    add_index :coop_core_fields, %i[account_id producer_id]
    add_index :coop_core_fields, 'producer_id, lower(name)',
              unique: true,
              name: 'index_coop_core_fields_on_producer_id_and_lower_name'
  end
end
