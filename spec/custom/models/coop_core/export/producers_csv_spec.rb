# frozen_string_literal: true

require 'rails_helper'

# Synchronous producers export (design §6.4/§13 S7). Locale-neutral data
# contract (design §6.3): ISO-8601 timestamps, E.164 phone, 11-digit cuit
# plus cuit_formatted.
RSpec.describe CoopCore::Export::ProducersCsv do
  let(:account) { create(:account) }

  describe '#call' do
    subject(:result) { described_class.new(CoopCore::Producer.where(account: account)).call }

    it 'includes the header row' do
      expect(CSV.parse(result).first).to eq(CoopCore::Export::ProducersCsv::HEADERS)
    end

    it 'includes one row per producer' do
      create_list(:coop_core_producer, 2, account: account)

      expect(CSV.parse(result, headers: true).count).to eq(2)
    end

    it 'renders the created_at timestamp as ISO-8601' do
      producer = create(:coop_core_producer, account: account)

      row = CSV.parse(result, headers: true).first

      expect(row['created_at']).to eq(producer.created_at.iso8601)
    end

    it 'renders the cuit_formatted convenience column' do
      create(:coop_core_producer, account: account, cuit: '20-12345678-6')

      row = CSV.parse(result, headers: true).first

      expect(row['cuit_formatted']).to eq('20-12345678-6')
    end

    it 'round-trips a business_name containing a comma' do
      create(:coop_core_producer, account: account, business_name: 'El Trigal, S.A.')

      row = CSV.parse(result, headers: true).first

      expect(row['business_name']).to eq('El Trigal, S.A.')
    end

    it 'renders a nil branch_id as an empty column' do
      create(:coop_core_producer, account: account, branch: nil)

      row = CSV.parse(result, headers: true).first

      expect(row['branch_id']).to be_nil
    end

    it 'renders the linked contact_id' do
      contact = create(:contact, account: account)
      producer = create(:coop_core_producer, account: account)
      producer.link_contact(contact)

      row = CSV.parse(result, headers: true).first

      expect(row['contact_id']).to eq(contact.id.to_s)
    end
  end

  describe '#rows' do
    it 'returns one hash per producer keyed by header' do
      producer = create(:coop_core_producer, account: account)

      rows = described_class.new(CoopCore::Producer.where(account: account)).rows

      expect(rows).to eq([{
                           'id' => producer.id,
                           'business_name' => producer.business_name,
                           'trade_name' => producer.trade_name,
                           'producer_type' => producer.producer_type,
                           'cuit' => producer.cuit,
                           'cuit_formatted' => producer.cuit_formatted,
                           'primary_phone' => producer.primary_phone,
                           'email' => producer.email,
                           'status' => producer.status,
                           'branch_id' => producer.branch_id,
                           'contact_id' => producer.contact_id,
                           'external_ref' => producer.external_ref,
                           'created_at' => producer.created_at.iso8601,
                           'updated_at' => producer.updated_at.iso8601
                         }])
    end
  end
end
