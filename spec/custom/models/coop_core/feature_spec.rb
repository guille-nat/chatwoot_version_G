# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CoopCore::Feature, type: :model do
  let(:account) { create(:account) }

  describe '.set_account_override' do
    context 'when a concurrent write already inserted the account-scope row (RecordNotUnique race)' do
      subject(:result) { described_class.set_account_override(:market, account: account, enabled: true) }

      let(:call_count) { [0] }

      before do
        allow(CoopCore::ModuleSetting).to receive(:find_or_initialize_by).and_wrap_original do |original, *args|
          call_count[0] += 1
          next original.call(*args) if call_count[0] > 1

          create(:coop_core_module_setting, account: account, module_key: 'market', scope_type: 'account', enabled: false)
          raise ActiveRecord::RecordNotUnique, 'duplicate key value violates unique constraint'
        end
      end

      it 'retries once and updates the row the competing request inserted' do
        aggregate_failures do
          expect(result.enabled).to be true
          expect(CoopCore::ModuleSetting.where(account_id: account.id, module_key: 'market', scope_type: 'account').count).to eq(1)
        end
      end
    end
  end
end
