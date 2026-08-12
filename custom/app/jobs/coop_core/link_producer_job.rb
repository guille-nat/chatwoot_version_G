# Runs the CoopCore::Producer::ContactLinkable matching for one contact, off
# the event-dispatch thread (CoopCoreListener only enqueues; the actual work
# happens here). Low-priority: linking is best-effort background enrichment,
# never blocks a conversational flow. Idempotent under at-least-once
# delivery -- ContactLinkable#link_contact is itself idempotent, so
# dispatching the same event twice is safe (see
# spec/custom/listeners/coop_core_listener_spec.rb for the double-dispatch
# coverage through the real event pipeline).
class CoopCore::LinkProducerJob < ApplicationJob
  queue_as :low

  def perform(account_id, contact_id)
    account = Account.find_by(id: account_id)
    contact = Contact.find_by(id: contact_id)
    return if account.blank? || contact.blank?
    return unless ::CoopCore::Feature.enabled?(:producers, account: account)

    ::CoopCore::Producer.auto_link_contact(contact)
  end
end
