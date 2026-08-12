# Auto-included into ::Contact by the existing Contact.include_mod_with('Concerns::Contact')
# call (app/models/contact.rb:255) -- zero core edits required (design D4),
# same mechanism as Custom::Concerns::Account.
module Custom::Concerns::Contact
  extend ActiveSupport::Concern

  included do
    # coop_core_producers.contact_id carries a real DB FK to contacts with
    # ON DELETE SET NULL (db/migrate/20260811090000_create_coop_core_producers.rb)
    # as the backstop -- dependent: :nullify runs the same unlink
    # synchronously through Rails so callbacks/audit trail on the producer
    # still fire. Never dependent: :destroy: losing a contact must never
    # delete the producer record itself (design §8.4).
    has_one :coop_producer, class_name: '::CoopCore::Producer', foreign_key: :contact_id, dependent: :nullify, inverse_of: :contact
  end
end
