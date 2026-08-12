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
  # S6: coop_core_staff_roles/staff_profiles/staff_role_assignments all carry
  # the same kind of real, non-deferrable DB FK to accounts (or cascade
  # through staff_profiles/staff_roles) as the tables above. A zero-child-row
  # regression spec proves nothing (design lesson from the S4a review-fix) --
  # this assignment row exercises the full account -> staff_profile ->
  # staff_role_assignment <- staff_role cascade through Account#destroy!.
  # system: true is the realistic case -- ensure_seeded! always creates
  # system roles, and system roles carry a before_destroy abort guard
  # (CoopCore::StaffRole#reject_system_role_deletion). A plain (non-system)
  # role here would not exercise that guard at all.
  let(:staff_user) { create(:user, account: account) }
  let!(:staff_role) { create(:coop_core_staff_role, account: account, system: true) }
  let!(:staff_profile) { create(:coop_core_staff_profile, account: account, user: staff_user) }
  let!(:staff_role_assignment) do
    create(:coop_core_staff_role_assignment, account: account, staff_profile: staff_profile, staff_role: staff_role)
  end
  # Review-fix (S6): branch_id now carries on_delete: :cascade (not
  # :nullify), and CoopCore::Branch also declares
  # has_many :staff_role_assignments, dependent: :destroy. That means this
  # branch-scoped row can be destroyed twice over during Account#destroy! --
  # once when `coop_branches` destroys `branch` (app-level cascade), and
  # again (a no-op, since it is already gone) when `coop_staff_profiles`
  # destroys `staff_profile`'s remaining role_assignments. Exercise that
  # path explicitly so a destroy-ordering regression doesn't just silently
  # pass because the account-level spec above never used a branch-scoped row.
  let!(:branch_scoped_staff_role_assignment) do
    create(:coop_core_staff_role_assignment, account: account, staff_profile: staff_profile, staff_role: staff_role, branch: branch)
  end

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
      expect(CoopCore::StaffRole.exists?(staff_role.id)).to be false
      expect(CoopCore::StaffProfile.exists?(staff_profile.id)).to be false
      expect(CoopCore::StaffRoleAssignment.exists?(staff_role_assignment.id)).to be false
      expect(CoopCore::StaffRoleAssignment.exists?(branch_scoped_staff_role_assignment.id)).to be false
    end
  end
end
