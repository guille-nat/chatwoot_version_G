# frozen_string_literal: true

require 'rails_helper'

# Design §8.3/§8.4: strong signals only (phone or CUIT), never ambiguous,
# never overwrite an existing link. Real DB constraints (the partial unique
# index on coop_core_producers (account_id, contact_id)) are the actual race
# guard -- #link_contact rescues ActiveRecord::RecordNotUnique rather than
# pre-checking, same lesson as the S4a/S4b review-fixes.
RSpec.describe CoopCore::Producer::ContactLinkable do
  let(:account) { create(:account) }

  describe '.auto_link_contact' do
    context 'when a producer stores the phone without the Argentine mobile marker' do
      it 'links the producer' do
        producer = create(:coop_core_producer, account: account, primary_phone: '+541122334455')
        contact = create(:contact, account: account, phone_number: '+5491122334455')

        CoopCore::Producer.auto_link_contact(contact)

        expect(producer.reload.contact_id).to eq(contact.id)
      end
    end

    context 'when a producer stores the phone with the Argentine mobile marker' do
      it 'links the producer' do
        producer = create(:coop_core_producer, account: account, primary_phone: '+5491122334455')
        contact = create(:contact, account: account, phone_number: '+541122334455')

        CoopCore::Producer.auto_link_contact(contact)

        expect(producer.reload.contact_id).to eq(contact.id)
      end
    end

    context 'when the contact CUIT matches a producer CUIT' do
      it 'links the producer' do
        producer = create(:coop_core_producer, account: account, cuit: '20-12345678-6')
        contact = create(:contact, account: account, additional_attributes: { 'cuit' => '20-12345678-6' })

        CoopCore::Producer.auto_link_contact(contact)

        expect(producer.reload.contact_id).to eq(contact.id)
      end
    end

    context 'when no producer matches' do
      it 'returns false' do
        contact = create(:contact, account: account, phone_number: '+5491122334455')

        expect(CoopCore::Producer.auto_link_contact(contact)).to be false
      end
    end

    context 'when multiple producers match' do
      it 'does not link any producer' do
        contact = create(:contact, account: account, phone_number: '+5491122334455')
        create(:coop_core_producer, account: account, primary_phone: contact.phone_number)
        create(:coop_core_producer, account: account, primary_phone: contact.phone_number)

        CoopCore::Producer.auto_link_contact(contact)

        expect(CoopCore::Producer.where(account: account).pluck(:contact_id)).to all(be_nil)
      end

      it 'logs a structured link_conflict warning' do
        contact = create(:contact, account: account, phone_number: '+5491122334455')
        create(:coop_core_producer, account: account, primary_phone: contact.phone_number)
        create(:coop_core_producer, account: account, primary_phone: contact.phone_number)

        expect(Rails.logger).to receive(:warn).with(/\[CoopCore\] link_conflict/)

        CoopCore::Producer.auto_link_contact(contact)
      end
    end

    context 'when the producer already has a different contact linked' do
      it 'does not overwrite the existing link' do
        other_contact = create(:contact, account: account)
        producer = create(:coop_core_producer, account: account, cuit: '20-12345678-6', contact_id: other_contact.id)
        contact = create(:contact, account: account, additional_attributes: { 'cuit' => '20-12345678-6' })

        CoopCore::Producer.auto_link_contact(contact)

        expect(producer.reload.contact_id).to eq(other_contact.id)
      end
    end

    context 'when the matching producer is in a different account' do
      it 'does not link it' do
        other_account = create(:account)
        contact = create(:contact, account: account, phone_number: '+5491122334455')
        other_producer = create(:coop_core_producer, account: other_account, primary_phone: contact.phone_number)

        CoopCore::Producer.auto_link_contact(contact)

        expect(other_producer.reload.contact_id).to be_nil
      end
    end
  end

  describe '#link_contact' do
    context 'when the producer has no contact linked' do
      it 'links the contact' do
        producer = create(:coop_core_producer, account: account)
        contact = create(:contact, account: account)

        expect(producer.link_contact(contact)).to be true
      end
    end

    context 'when the producer is already linked to the same contact' do
      it 'is idempotent' do
        contact = create(:contact, account: account)
        producer = create(:coop_core_producer, account: account, contact_id: contact.id)

        expect(producer.link_contact(contact)).to be true
      end
    end

    context 'when the producer is already linked to a different contact' do
      it 'does not link' do
        linked_contact = create(:contact, account: account)
        producer = create(:coop_core_producer, account: account, contact_id: linked_contact.id)
        other_contact = create(:contact, account: account)

        expect(producer.link_contact(other_contact)).to be false
      end
    end

    context 'when the contact is already linked to a different producer' do
      it 'does not link' do
        contact = create(:contact, account: account)
        create(:coop_core_producer, account: account, contact_id: contact.id)
        unlinked_producer = create(:coop_core_producer, account: account)

        expect(unlinked_producer.link_contact(contact)).to be false
      end

      it 'does not raise' do
        contact = create(:contact, account: account)
        create(:coop_core_producer, account: account, contact_id: contact.id)
        unlinked_producer = create(:coop_core_producer, account: account)

        expect { unlinked_producer.link_contact(contact) }.not_to raise_error
      end
    end
  end

  describe '#unlink_contact' do
    it 'clears the contact_id' do
      contact = create(:contact, account: account)
      producer = create(:coop_core_producer, account: account, contact_id: contact.id)

      producer.unlink_contact

      expect(producer.reload.contact_id).to be_nil
    end

    it 'is idempotent when already unlinked' do
      producer = create(:coop_core_producer, account: account)

      expect { producer.unlink_contact }.not_to raise_error
    end
  end
end
