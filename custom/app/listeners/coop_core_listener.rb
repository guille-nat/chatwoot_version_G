# Real handlers land in S5 (auto-link producers to contacts, design §8.2).
# Every handler is wrapped in #with_safety: a CoopFlow bug must never break
# Chatwoot's own event pipeline -- Wisper listeners share the dispatch loop
# with WebhookListener, NotificationListener, etc, so an unrescued exception
# here would take down (or force a retry storm on) EventDispatcherJob for
# everyone, not just CoopFlow. Handlers only extract the contact, check the
# module gate, and enqueue -- the actual matching runs in
# CoopCore::LinkProducerJob, off the dispatch thread.
class CoopCoreListener < BaseListener
  def contact_created(event)
    with_safety do
      contact, account = extract_contact_and_account(event)
      link_contact_later(contact, account)
    end
  end

  def contact_updated(event)
    with_safety do
      contact, account = extract_contact_and_account(event)
      link_contact_later(contact, account)
    end
  end

  def conversation_created(event)
    with_safety do
      conversation, account = extract_conversation_and_account(event)
      link_contact_later(conversation.contact, account)
    end
  end

  private

  def link_contact_later(contact, account)
    return if contact.blank?
    return unless ::CoopCore::Feature.enabled?(:producers, account: account)

    ::CoopCore::LinkProducerJob.perform_later(account.id, contact.id)
  end

  def with_safety
    yield
  rescue StandardError => e
    ChatwootExceptionTracker.new(e).capture_exception
    nil
  end
end
