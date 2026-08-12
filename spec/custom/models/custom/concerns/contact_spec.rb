# frozen_string_literal: true

require 'rails_helper'

# Custom::Concerns::Contact is auto-included into ::Contact by the existing
# Contact.include_mod_with('Concerns::Contact') call (app/models/contact.rb),
# mirroring Custom::Concerns::Account (design D4). Covers the has_one
# association only -- ContactLinkable owns the actual matching/linking logic.
RSpec.describe 'Custom::Concerns::Contact', type: :model do
  let(:account) { create(:account) }
  let(:contact) { create(:contact, account: account) }

  it 'exposes a coop_producer association' do
    expect(contact.respond_to?(:coop_producer)).to be true
  end

  context 'when the contact is linked to a producer' do
    let!(:producer) { create(:coop_core_producer, account: account, contact_id: contact.id) }

    it 'returns the linked producer' do
      expect(contact.coop_producer).to eq(producer)
    end

    it 'does not raise when the contact is destroyed' do
      expect { contact.destroy! }.not_to raise_error
    end

    it 'unlinks the producer when the contact is destroyed' do
      contact.destroy!

      expect(producer.reload.contact_id).to be_nil
    end
  end
end
