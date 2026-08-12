# Producer<->Contact auto-matching (design §8.3/§8.4). Candidate lookup and
# ambiguity handling live in ContactLinkable::Matcher; idempotency and the
# actual concurrency guard live at the DB layer (the partial unique index on
# coop_core_producers (account_id, contact_id)) -- #link_contact rescues the
# resulting ActiveRecord::RecordNotUnique instead of pre-checking for a race,
# same lesson as the S4a/S4b review-fixes on cross-account FK validations.
module CoopCore::Producer::ContactLinkable
  extend ActiveSupport::Concern

  class_methods do
    # Entry point for the auto-link flows (contact_created/updated,
    # conversation_created -- see CoopCoreListener + CoopCore::LinkProducerJob).
    # Returns true when a producer was linked (or already linked to this
    # contact), false when nothing matched or the match was ambiguous.
    def auto_link_contact(contact)
      # Compact module definition (`module CoopCore::Producer::ContactLinkable`)
      # keeps only that exact path in Module.nesting -- a bare `ContactLinkable::Matcher`
      # reference here does not resolve (same Zeitwerk pitfall design doc §2.1
      # warns about for nested `module A; module B` style, mirrored here).
      ::CoopCore::Producer::ContactLinkable::Matcher.new(self, contact).link
    end
  end

  # Manual entry point too (POST /coop/producers/:id/contact_link). Never
  # overwrites an existing link (idempotent success when it's the same
  # contact); relies on the DB partial unique index to reject linking a
  # contact that another producer already claimed.
  def link_contact(contact)
    return true if contact_id == contact.id
    return false if contact_id.present?

    update!(contact_id: contact.id)
    true
  rescue ActiveRecord::RecordNotUnique
    reload
    contact_id == contact.id
  end

  # Manual entry point (DELETE /coop/producers/:id/contact_link). Idempotent.
  def unlink_contact
    update!(contact_id: nil) if contact_id.present?
    true
  end
end
