# frozen_string_literal: true

require 'rails_helper'

# Driven through Rails.configuration.dispatcher.dispatch (design §10) --
# calling the listener's methods directly would leave the real Wisper/
# AsyncDispatcher/EventDispatcherJob wiring untested. `dispatch` enqueues
# EventDispatcherJob; only performing that job triggers publish_event, which
# broadcasts to every registered async listener (including CoopCoreListener).
RSpec.describe CoopCoreListener do
  let(:account) { create(:account) }
  let(:contact) { create(:contact, account: account, phone_number: '+5491122334455') }

  def dispatch_event(event_name, data)
    perform_enqueued_jobs(only: [EventDispatcherJob, CoopCore::LinkProducerJob]) do
      Rails.configuration.dispatcher.dispatch(event_name, Time.zone.now, data)
    end
  end

  describe 'contact_created' do
    it 'links a matching producer' do
      producer = create(:coop_core_producer, account: account, primary_phone: contact.phone_number)

      dispatch_event(Events::Types::CONTACT_CREATED, contact: contact)

      expect(producer.reload.contact_id).to eq(contact.id)
    end

    it 'does not enqueue a link job when the producers module is disabled' do
      CoopCore::Feature.set_account_override(:producers, account: account, enabled: false)

      expect do
        perform_enqueued_jobs(only: EventDispatcherJob) do
          Rails.configuration.dispatcher.dispatch(Events::Types::CONTACT_CREATED, Time.zone.now, contact: contact)
        end
      end.not_to have_enqueued_job(CoopCore::LinkProducerJob)
    end
  end

  describe 'contact_updated' do
    it 'links a matching producer' do
      producer = create(:coop_core_producer, account: account, primary_phone: contact.phone_number)

      dispatch_event(Events::Types::CONTACT_UPDATED, contact: contact, changed_attributes: {})

      expect(producer.reload.contact_id).to eq(contact.id)
    end
  end

  describe 'conversation_created' do
    it 'links a producer matching the conversation contact' do
      producer = create(:coop_core_producer, account: account, primary_phone: contact.phone_number)
      conversation = create(:conversation, account: account, contact: contact)

      dispatch_event(Events::Types::CONVERSATION_CREATED, conversation: conversation)

      expect(producer.reload.contact_id).to eq(contact.id)
    end
  end

  describe 'error handling' do
    it 'does not propagate a listener error' do
      linked_contact = contact
      allow(CoopCore::LinkProducerJob).to receive(:perform_later).and_raise(StandardError, 'boom')

      expect do
        perform_enqueued_jobs(only: EventDispatcherJob) do
          Rails.configuration.dispatcher.dispatch(Events::Types::CONTACT_CREATED, Time.zone.now, contact: linked_contact)
        end
      end.not_to raise_error
    end

    it 'reports the swallowed error via ChatwootExceptionTracker' do
      linked_contact = contact
      allow(CoopCore::LinkProducerJob).to receive(:perform_later).and_raise(StandardError, 'boom')
      tracker = instance_double(ChatwootExceptionTracker, capture_exception: nil)
      allow(ChatwootExceptionTracker).to receive(:new).and_return(tracker)

      perform_enqueued_jobs(only: EventDispatcherJob) do
        Rails.configuration.dispatcher.dispatch(Events::Types::CONTACT_CREATED, Time.zone.now, contact: linked_contact)
      end

      expect(tracker).to have_received(:capture_exception)
    end
  end

  describe 'idempotency' do
    it 'links exactly once when the same event is dispatched twice' do
      producer = create(:coop_core_producer, account: account, primary_phone: contact.phone_number)

      dispatch_event(Events::Types::CONTACT_CREATED, contact: contact)
      dispatch_event(Events::Types::CONTACT_CREATED, contact: contact)

      expect(producer.reload.contact_id).to eq(contact.id)
    end

    it 'does not raise when the same event is dispatched twice' do
      create(:coop_core_producer, account: account, primary_phone: contact.phone_number)

      expect do
        dispatch_event(Events::Types::CONTACT_CREATED, contact: contact)
        dispatch_event(Events::Types::CONTACT_CREATED, contact: contact)
      end.not_to raise_error
    end
  end
end
