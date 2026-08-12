class CreateCoopCoreEventSubscriptions < ActiveRecord::Migration[7.1]
  def change
    create_table :coop_core_event_subscriptions do |t|
      # accounts.id is `serial` (int4), never bigint -- see custom/README.md
      # / design R10.
      t.integer :account_id, null: false
      t.string :url, null: false
      # Encrypted at the app layer (CoopCore::EventSubscription includes the
      # existing WebhookSecretable concern, app/models/concerns/
      # webhook_secretable.rb -- `has_secure_token :secret` +
      # `encrypts :secret if Chatwoot.encryption_configured?`), same as the
      # core `Webhook` model's own `secret` column (db/schema.rb:1498,
      # unlimited t.string, no explicit length cap). No column-level
      # constraint changes needed for encryption -- ActiveRecord::Encryption
      # ciphertext is base64 and Postgres varchar without a limit accepts
      # arbitrary length, same as the `webhooks` table.
      t.string :secret, null: false
      t.text :event_keys, array: true, null: false, default: []
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_foreign_key :coop_core_event_subscriptions, :accounts, column: :account_id
    add_index :coop_core_event_subscriptions, %i[account_id active]
  end
end
