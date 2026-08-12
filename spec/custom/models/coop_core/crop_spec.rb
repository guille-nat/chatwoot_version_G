# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CoopCore::Crop, type: :model do
  let(:account) { create(:account) }
  let(:producer) { create(:coop_core_producer, account: account) }
  let(:field) { create(:coop_core_field, account: account, producer: producer) }
  let(:plot) { create(:coop_core_plot, account: account, field: field) }

  describe 'validations' do
    it 'is invalid without a species' do
      crop = build(:coop_core_crop, account: account, plot: plot, species: nil)

      expect(crop).not_to be_valid
    end

    it 'is invalid with an unknown species' do
      crop = build(:coop_core_crop, account: account, plot: plot, species: 'banana')

      expect(crop).not_to be_valid
    end

    it 'is valid with a known species' do
      crop = build(:coop_core_crop, account: account, plot: plot, species: 'maiz')

      expect(crop).to be_valid
    end

    it 'is invalid without a plot' do
      crop = build(:coop_core_crop, account: account, plot: nil)

      expect(crop).not_to be_valid
    end

    context 'with a malformed campaign' do
      it 'is invalid' do
        crop = build(:coop_core_crop, account: account, plot: plot, campaign: '2025')

        expect(crop).not_to be_valid
      end
    end

    it 'is valid with a well-formed campaign' do
      crop = build(:coop_core_crop, account: account, plot: plot, campaign: '2025/26')

      expect(crop).to be_valid
    end

    it 'is invalid with an unknown status' do
      crop = build(:coop_core_crop, account: account, plot: plot, status: 'exploded')

      expect(crop).not_to be_valid
    end

    context 'with a negative hectares' do
      it 'is invalid' do
        crop = build(:coop_core_crop, account: account, plot: plot, hectares: -1)

        expect(crop).not_to be_valid
      end
    end

    context 'when the account does not match the plot account' do
      it 'is invalid' do
        other_account = create(:account)
        crop = build(:coop_core_crop, account: other_account, plot: plot)

        expect(crop).not_to be_valid
      end
    end
  end

  describe 'defaults' do
    it 'defaults status to planned' do
      crop = described_class.new

      expect(crop.status).to eq('planned')
    end
  end

  describe 'auditing' do
    it 'is audited' do
      expect(described_class.auditing_enabled).to be true
    end
  end
end
