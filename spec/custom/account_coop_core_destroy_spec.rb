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
  # S4b: coop_core_fields/plots/crops all carry the same kind of real,
  # non-deferrable DB FK (to coop_core_producers/coop_core_fields/
  # coop_core_plots respectively) as the S4a tables above. A regression spec
  # with zero child rows proves nothing (design lesson from the S4a
  # review-fix) -- these rows exercise the full producer -> field -> plot ->
  # crop cascade through Account#destroy!.
  let!(:field) { create(:coop_core_field, account: account, producer: producer, branch: branch) }
  let!(:plot) { create(:coop_core_plot, account: account, field: field) }
  let!(:crop) { create(:coop_core_crop, account: account, plot: plot) }

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
      expect(CoopCore::Field.exists?(field.id)).to be false
      expect(CoopCore::Plot.exists?(plot.id)).to be false
      expect(CoopCore::Crop.exists?(crop.id)).to be false
    end
  end
end
