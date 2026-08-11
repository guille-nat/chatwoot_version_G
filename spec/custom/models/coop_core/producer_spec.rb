# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CoopCore::Producer, type: :model do
  let(:account) { create(:account) }

  describe 'validations' do
    it 'is invalid without a business_name' do
      producer = build(:coop_core_producer, account: account, business_name: nil)

      expect(producer).not_to be_valid
    end

    it 'is valid without a cuit' do
      producer = build(:coop_core_producer, account: account, cuit: nil)

      expect(producer).to be_valid
    end

    context 'with a valid mod-11 CUIT' do
      it 'is valid' do
        producer = build(:coop_core_producer, account: account, cuit: '20-12345678-6')

        expect(producer).to be_valid
      end
    end

    context 'with an invalid check digit' do
      it 'is invalid' do
        producer = build(:coop_core_producer, account: account, cuit: '20-12345678-0')

        expect(producer).not_to be_valid
      end

      it 'adds an error on cuit' do
        producer = build(:coop_core_producer, account: account, cuit: '20-12345678-0')
        producer.valid?

        expect(producer.errors[:cuit]).to be_present
      end
    end

    context 'with an unknown type prefix' do
      it 'is invalid' do
        producer = build(:coop_core_producer, account: account, cuit: '99-12345678-3')

        expect(producer).not_to be_valid
      end
    end

    context 'with a duplicate cuit within the same account' do
      it 'is invalid' do
        create(:coop_core_producer, account: account, cuit: '20-12345678-6')
        duplicate = build(:coop_core_producer, account: account, cuit: '20-12345678-6')

        expect(duplicate).not_to be_valid
      end
    end

    context 'with the same cuit across different cooperatives' do
      it 'is valid' do
        other_account = create(:account)
        create(:coop_core_producer, account: account, cuit: '20-12345678-6')
        other_producer = build(:coop_core_producer, account: other_account, cuit: '20-12345678-6')

        expect(other_producer).to be_valid
      end
    end

    context 'with a duplicate external_ref within the same account' do
      it 'is invalid' do
        create(:coop_core_producer, account: account, external_ref: 'ERP-001')
        duplicate = build(:coop_core_producer, account: account, external_ref: 'ERP-001')

        expect(duplicate).not_to be_valid
      end
    end

    context 'with a blank external_ref on two producers in the same account' do
      it 'is valid for both' do
        create(:coop_core_producer, account: account, external_ref: '')
        second = build(:coop_core_producer, account: account, external_ref: '')

        expect(second).to be_valid
      end
    end
  end

  describe 'normalization' do
    it 'stores the cuit as normalized 11 digits' do
      producer = create(:coop_core_producer, account: account, cuit: '20-12345678-6')

      expect(producer.cuit).to eq('20123456786')
    end

    it 'stores a blank external_ref as nil' do
      producer = create(:coop_core_producer, account: account, external_ref: '')

      expect(producer.external_ref).to be_nil
    end
  end

  describe 'defaults' do
    it 'defaults producer_type to individual' do
      producer = described_class.new

      expect(producer.producer_type).to eq('individual')
    end

    it 'defaults status to active' do
      producer = described_class.new

      expect(producer.status).to eq('active')
    end
  end

  describe '#cuit_formatted' do
    it 'renders the XX-XXXXXXXX-X display form' do
      producer = create(:coop_core_producer, account: account, cuit: '20-12345678-6')

      expect(producer.cuit_formatted).to eq('20-12345678-6')
    end

    it 'returns nil when the cuit is blank' do
      producer = build(:coop_core_producer, account: account, cuit: nil)

      expect(producer.cuit_formatted).to be_nil
    end
  end

  describe 'auditing' do
    it 'is audited' do
      expect(described_class.auditing_enabled).to be true
    end
  end

  describe 'Account association' do
    it 'is included in the owning account coop_producers association' do
      producer = create(:coop_core_producer, account: account)

      expect(account.coop_producers).to include(producer)
    end

    it 'does not include producers belonging to a different account' do
      other_account = create(:account)
      other_producer = create(:coop_core_producer, account: other_account)

      expect(account.coop_producers).not_to include(other_producer)
    end
  end
end
