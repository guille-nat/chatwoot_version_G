# frozen_string_literal: true

require 'rails_helper'

# Thin job: load, guard (module gate), delegate to
# CoopCore::Producer::ContactLinkable.auto_link_contact. Idempotent under
# at-least-once delivery -- see spec/custom/listeners/coop_core_listener_spec.rb
# for the double-dispatch coverage driven through the real event pipeline.
RSpec.describe CoopCore::LinkProducerJob do
  let(:account) { create(:account) }
  let(:contact) { create(:contact, account: account, phone_number: '+5491122334455') }

  describe '#perform' do
    context 'when the producers module is enabled' do
      it 'links a matching producer' do
        producer = create(:coop_core_producer, account: account, primary_phone: contact.phone_number)

        described_class.perform_now(account.id, contact.id)

        expect(producer.reload.contact_id).to eq(contact.id)
      end
    end

    context 'when the producers module is disabled' do
      it 'does not link a matching producer' do
        CoopCore::Feature.set_account_override(:producers, account: account, enabled: false)
        producer = create(:coop_core_producer, account: account, primary_phone: contact.phone_number)

        described_class.perform_now(account.id, contact.id)

        expect(producer.reload.contact_id).to be_nil
      end
    end

    context 'when the account no longer exists' do
      it 'does not raise' do
        expect { described_class.perform_now(0, contact.id) }.not_to raise_error
      end
    end

    context 'when the contact no longer exists' do
      it 'does not raise' do
        expect { described_class.perform_now(account.id, 0) }.not_to raise_error
      end
    end
  end
end
