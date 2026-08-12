# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CoopCore::Field, type: :model do
  let(:account) { create(:account) }
  let(:producer) { create(:coop_core_producer, account: account) }

  describe 'validations' do
    it 'is invalid without a name' do
      field = build(:coop_core_field, account: account, producer: producer, name: nil)

      expect(field).not_to be_valid
    end

    it 'is invalid without a producer' do
      field = build(:coop_core_field, account: account, producer: nil)

      expect(field).not_to be_valid
    end

    it 'is valid with only a name and a producer' do
      field = build(:coop_core_field, account: account, producer: producer)

      expect(field).to be_valid
    end

    context 'with a duplicate name (case-insensitive) under the same producer' do
      it 'is invalid' do
        create(:coop_core_field, account: account, producer: producer, name: 'Campo Norte')
        duplicate = build(:coop_core_field, account: account, producer: producer, name: 'campo norte')

        expect(duplicate).not_to be_valid
      end
    end

    context 'with the same name under a different producer' do
      it 'is valid' do
        create(:coop_core_field, account: account, producer: producer, name: 'Campo Norte')
        other_producer = create(:coop_core_producer, account: account)
        other_field = build(:coop_core_field, account: account, producer: other_producer, name: 'Campo Norte')

        expect(other_field).to be_valid
      end
    end

    context 'with a negative total_hectares' do
      it 'is invalid' do
        field = build(:coop_core_field, account: account, producer: producer, total_hectares: -1)

        expect(field).not_to be_valid
      end
    end

    it 'is valid without a total_hectares' do
      field = build(:coop_core_field, account: account, producer: producer, total_hectares: nil)

      expect(field).to be_valid
    end

    context 'when the account does not match the producer account' do
      it 'is invalid' do
        other_account = create(:account)
        field = build(:coop_core_field, account: other_account, producer: producer)

        expect(field).not_to be_valid
      end
    end

    context 'when the account does not match the branch account' do
      it 'is invalid' do
        other_account = create(:account)
        other_branch = create(:coop_core_branch, account: other_account)
        field = build(:coop_core_field, account: account, producer: producer, branch: other_branch)

        expect(field).not_to be_valid
      end
    end
  end

  describe 'normalization' do
    it 'stores a blank external_ref as nil' do
      field = create(:coop_core_field, account: account, producer: producer, external_ref: '')

      expect(field.external_ref).to be_nil
    end
  end

  describe 'associations' do
    it 'destroys its plots when destroyed' do
      field = create(:coop_core_field, account: account, producer: producer)
      plot = create(:coop_core_plot, account: account, field: field)

      field.destroy!

      expect(CoopCore::Plot.exists?(plot.id)).to be false
    end
  end

  describe 'auditing' do
    it 'is audited' do
      expect(described_class.auditing_enabled).to be true
    end
  end
end
