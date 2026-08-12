class CreateCoopCoreEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :coop_core_events do |t|
      # accounts.id is `serial` (int4), never bigint -- see custom/README.md
      # / design R10.
      t.integer :account_id, null: false
      t.string :key, null: false
      t.jsonb :payload, null: false
      t.datetime :occurred_at, null: false
      # design §8.4 formula: "#{key}:#{subject_gid}:#{occurred_at.to_i}" --
      # the unique index below is the real idempotency guard (CoopCore::Event
      # .publish rescues ActiveRecord::RecordNotUnique as a successful
      # no-op), same "DB index over app-level pre-check" lesson as the
      # producers.contact_id race guard (migration 20260811090000).
      t.string :idempotency_key, null: false

      t.timestamps
    end

    add_foreign_key :coop_core_events, :accounts, column: :account_id
    add_index :coop_core_events, %i[account_id idempotency_key],
              unique: true,
              name: 'index_coop_core_events_on_account_id_and_idempotency_key'
    add_index :coop_core_events, %i[account_id key occurred_at]
  end
end
