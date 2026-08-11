# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CoopCore::ModuleSetting, type: :model do
  let(:account) { create(:account) }

  describe 'validations' do
    context 'when scope_type is account' do
      it 'is invalid with a duplicate account-scope row for the same module' do
        create(:coop_core_module_setting, account: account, module_key: 'market', scope_type: 'account')
        duplicate = build(:coop_core_module_setting, account: account, module_key: 'market', scope_type: 'account')

        expect(duplicate).not_to be_valid
      end

      it 'raises RecordInvalid, not RecordNotUnique, when a duplicate is saved' do
        create(:coop_core_module_setting, account: account, module_key: 'market', scope_type: 'account')
        duplicate = build(:coop_core_module_setting, account: account, module_key: 'market', scope_type: 'account')

        expect { duplicate.save! }.to raise_error(ActiveRecord::RecordInvalid)
      end

      it 'is invalid with a stray scope_id' do
        setting = build(:coop_core_module_setting, account: account, module_key: 'market', scope_type: 'account', scope_id: 1)

        expect(setting).not_to be_valid
      end

      it 'is invalid with a stray scope_key' do
        setting = build(:coop_core_module_setting, account: account, module_key: 'market', scope_type: 'account', scope_key: 'pilot')

        expect(setting).not_to be_valid
      end
    end

    %w[branch staff_role user].each do |scope_type|
      context "when scope_type is #{scope_type}" do
        it 'is valid with a scope_id and no scope_key' do
          setting = build(:coop_core_module_setting, account: account, module_key: 'market', scope_type: scope_type, scope_id: 1)

          expect(setting).to be_valid
        end

        it 'is invalid with a stray scope_key' do
          setting = build(:coop_core_module_setting, account: account, module_key: 'market', scope_type: scope_type, scope_id: 1, scope_key: 'pilot')

          expect(setting).not_to be_valid
        end
      end
    end

    context 'when scope_type is beta_group' do
      it 'is valid with a scope_key and no scope_id' do
        setting = build(:coop_core_module_setting, account: account, module_key: 'market', scope_type: 'beta_group', scope_key: 'pilot')

        expect(setting).to be_valid
      end

      it 'is invalid with a stray scope_id' do
        setting = build(:coop_core_module_setting, account: account, module_key: 'market', scope_type: 'beta_group', scope_key: 'pilot', scope_id: 1)

        expect(setting).not_to be_valid
      end
    end
  end
end
