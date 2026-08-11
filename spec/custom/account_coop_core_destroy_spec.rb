# frozen_string_literal: true

require 'rails_helper'

# Focused regression spec for Account#destroy! against the coop_core tables
# that carry a real, non-deferrable DB foreign key to accounts (see
# db/schema.rb: coop_core_producers, coop_core_branches,
# coop_core_cooperative_profiles, coop_core_module_settings). Those FKs run
# inside the same transaction as `DELETE FROM accounts`, so the children
# must be destroyed synchronously before the account row delete --
# `dependent: :destroy_async` enqueues after commit and arrives too late.
# See custom/app/models/custom/concerns/account.rb.
RSpec.describe 'Account destroy with coop_core children', type: :model do
  let(:account) { create(:account) }
  let!(:branch) { create(:coop_core_branch, account: account) }
  let!(:producer) { create(:coop_core_producer, account: account, branch: branch) }
  let!(:cooperative_profile) { create(:coop_core_cooperative_profile, account: account) }
  let!(:module_setting) { create(:coop_core_module_setting, account: account) }

  it 'destroys the account without raising a foreign key error' do
    expect { account.destroy! }.not_to raise_error
  end

  it 'destroys the coop_core rows owned by the account' do
    account.destroy!

    aggregate_failures do
      expect(CoopCore::Producer.exists?(producer.id)).to be false
      expect(CoopCore::Branch.exists?(branch.id)).to be false
      expect(CoopCore::CooperativeProfile.exists?(cooperative_profile.id)).to be false
      expect(CoopCore::ModuleSetting.exists?(module_setting.id)).to be false
    end
  end
end
