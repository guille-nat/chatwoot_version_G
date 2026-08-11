class CreateCoopCoreProducers < ActiveRecord::Migration[7.1]
  def change
    create_table :coop_core_producers do |t|
      # accounts.id and contacts.id are `serial` (int4), never bigint -- see
      # custom/README.md / design R10. coop_core_branches.id is our own PK
      # (bigint, Rails default), so branch_id stays t.bigint.
      t.integer :account_id, null: false
      t.bigint :branch_id
      t.integer :contact_id
      t.string :cuit, limit: 11
      t.string :business_name, null: false
      t.string :trade_name
      t.string :producer_type, null: false, default: 'individual'
      t.string :primary_phone
      t.string :email
      t.string :status, null: false, default: 'active'
      t.string :external_ref
      t.jsonb :custom_attributes, null: false, default: {}
      t.text :notes

      t.timestamps
    end

    add_producer_indexes
    add_producer_foreign_keys
  end

  private

  def add_producer_foreign_keys
    add_foreign_key :coop_core_producers, :accounts, column: :account_id
    add_foreign_key :coop_core_producers, :coop_core_branches, column: :branch_id

    # contacts is the hottest, largest table in this app -- validate: false
    # defers lock acquisition to a separate migration (design §4.1 / the
    # rails-migration-safety skill). on_delete: :nullify matches design §4
    # ("contact_id ... FK->contacts ON DELETE SET NULL").
    add_foreign_key :coop_core_producers, :contacts, column: :contact_id, on_delete: :nullify, validate: false
  end

  def add_producer_indexes
    add_index :coop_core_producers, %i[account_id status]
    add_index :coop_core_producers, %i[account_id primary_phone]
    add_index :coop_core_producers, :branch_id
    add_index :coop_core_producers, 'account_id, cuit',
              unique: true,
              where: 'cuit IS NOT NULL',
              name: 'index_coop_core_producers_on_account_id_and_cuit'
    # Race guard for the auto-link flow (design §8.4, lands in S5): the
    # partial unique index is the real defense against two concurrent links
    # to the same contact, not application code alone.
    add_index :coop_core_producers, %i[account_id contact_id],
              unique: true,
              where: 'contact_id IS NOT NULL',
              name: 'index_coop_core_producers_on_account_id_and_contact_id'
    add_index :coop_core_producers, %i[account_id external_ref],
              unique: true,
              where: 'external_ref IS NOT NULL',
              name: 'index_coop_core_producers_on_account_id_and_external_ref'
  end
end
