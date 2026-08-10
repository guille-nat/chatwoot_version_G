# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CoopCore::CooperativeProfile, type: :model do
  let(:account) { create(:account) }

  describe 'validations' do
    it 'is invalid without an account' do
      profile = build(:coop_core_cooperative_profile, account: nil)

      expect(profile).not_to be_valid
    end

    it 'is invalid without a legal_name' do
      profile = build(:coop_core_cooperative_profile, account: account, legal_name: nil)

      expect(profile).not_to be_valid
    end

    it 'is invalid with a duplicate account_id' do
      create(:coop_core_cooperative_profile, account: account)
      duplicate = build(:coop_core_cooperative_profile, account: account)

      expect(duplicate).not_to be_valid
    end

    it 'allows different accounts to each have their own cooperative profile' do
      other_account = create(:account)
      create(:coop_core_cooperative_profile, account: account)
      other_profile = build(:coop_core_cooperative_profile, account: other_account)

      expect(other_profile).to be_valid
    end

    it 'is invalid with a malformed cuit' do
      profile = build(:coop_core_cooperative_profile, account: account, cuit: 'not-a-cuit')

      expect(profile).not_to be_valid
    end

    it 'is valid with a nil cuit' do
      profile = build(:coop_core_cooperative_profile, account: account, cuit: nil)

      expect(profile).to be_valid
    end
  end

  describe 'defaults' do
    it 'defaults locale to es-AR' do
      profile = described_class.new

      expect(profile.locale).to eq('es-AR')
    end

    it 'defaults timezone to America/Argentina/Buenos_Aires' do
      profile = described_class.new

      expect(profile.timezone).to eq('America/Argentina/Buenos_Aires')
    end

    it 'defaults currency to ARS' do
      profile = described_class.new

      expect(profile.currency).to eq('ARS')
    end
  end

  describe 'auditing' do
    it 'is audited' do
      expect(described_class.auditing_enabled).to be true
    end
  end
end
