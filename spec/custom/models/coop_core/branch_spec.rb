# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CoopCore::Branch, type: :model do
  let(:account) { create(:account) }

  describe 'validations' do
    it 'is invalid without a name' do
      branch = build(:coop_core_branch, account: account, name: nil)

      expect(branch).not_to be_valid
    end

    it 'is invalid with an unsupported kind' do
      branch = build(:coop_core_branch, account: account, kind: 'warehouse')

      expect(branch).not_to be_valid
    end

    it 'is valid without a code' do
      branch = build(:coop_core_branch, account: account, code: nil)

      expect(branch).to be_valid
    end

    it 'is invalid with a duplicate code within the same account' do
      create(:coop_core_branch, account: account, code: 'RSR-01')
      duplicate = build(:coop_core_branch, account: account, code: 'rsr-01')

      expect(duplicate).not_to be_valid
    end

    it 'allows the same code across different accounts' do
      other_account = create(:account)
      create(:coop_core_branch, account: account, code: 'RSR-01')
      other_branch = build(:coop_core_branch, account: other_account, code: 'RSR-01')

      expect(other_branch).to be_valid
    end
  end

  describe 'defaults' do
    it 'defaults kind to branch' do
      branch = described_class.new

      expect(branch.kind).to eq('branch')
    end

    it 'defaults active to true' do
      branch = described_class.new

      expect(branch.active).to be true
    end

    it 'defaults timezone to America/Argentina/Buenos_Aires' do
      branch = described_class.new

      expect(branch.timezone).to eq('America/Argentina/Buenos_Aires')
    end
  end

  describe 'auditing' do
    it 'is audited' do
      expect(described_class.auditing_enabled).to be true
    end
  end

  describe 'Account association' do
    it 'is included in the owning account coop_branches association' do
      branch = create(:coop_core_branch, account: account)

      expect(account.coop_branches).to include(branch)
    end

    it 'does not include branches belonging to a different account' do
      other_account = create(:account)
      other_branch = create(:coop_core_branch, account: other_account)

      expect(account.coop_branches).not_to include(other_branch)
    end
  end
end
