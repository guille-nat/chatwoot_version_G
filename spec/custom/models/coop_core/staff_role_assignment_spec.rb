# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CoopCore::StaffRoleAssignment, type: :model do
  let(:account) { create(:account) }
  let(:staff_profile) { create(:coop_core_staff_profile, account: account) }
  let(:staff_role) { create(:coop_core_staff_role, account: account) }

  describe 'validations' do
    it 'is valid with only an account, a staff_profile and a staff_role' do
      assignment = build(:coop_core_staff_role_assignment, account: account, staff_profile: staff_profile, staff_role: staff_role)

      expect(assignment).to be_valid
    end

    it 'is invalid without a staff_profile' do
      assignment = build(:coop_core_staff_role_assignment, account: account, staff_profile: nil, staff_role: staff_role)

      expect(assignment).not_to be_valid
    end

    it 'is invalid without a staff_role' do
      assignment = build(:coop_core_staff_role_assignment, account: account, staff_profile: staff_profile, staff_role: nil)

      expect(assignment).not_to be_valid
    end

    it 'is invalid with a duplicate (staff_profile, staff_role) pair with no branch' do
      create(:coop_core_staff_role_assignment, account: account, staff_profile: staff_profile, staff_role: staff_role, branch: nil)
      duplicate = build(:coop_core_staff_role_assignment, account: account, staff_profile: staff_profile, staff_role: staff_role, branch: nil)

      expect(duplicate).not_to be_valid
    end

    it 'is valid with the same (staff_profile, staff_role) pair under two different branches' do
      branch_a = create(:coop_core_branch, account: account)
      branch_b = create(:coop_core_branch, account: account)
      create(:coop_core_staff_role_assignment, account: account, staff_profile: staff_profile, staff_role: staff_role, branch: branch_a)
      other = build(:coop_core_staff_role_assignment, account: account, staff_profile: staff_profile, staff_role: staff_role, branch: branch_b)

      expect(other).to be_valid
    end

    it 'is invalid with a duplicate (staff_profile, staff_role, branch) triple' do
      branch = create(:coop_core_branch, account: account)
      create(:coop_core_staff_role_assignment, account: account, staff_profile: staff_profile, staff_role: staff_role, branch: branch)
      duplicate = build(:coop_core_staff_role_assignment, account: account, staff_profile: staff_profile, staff_role: staff_role, branch: branch)

      expect(duplicate).not_to be_valid
    end

    context 'when the account does not match the staff_profile account' do
      it 'is invalid' do
        other_account = create(:account)
        other_profile = create(:coop_core_staff_profile, account: other_account)
        assignment = build(:coop_core_staff_role_assignment, account: account, staff_profile: other_profile, staff_role: staff_role)

        expect(assignment).not_to be_valid
      end
    end

    context 'when the account does not match the staff_role account' do
      it 'is invalid' do
        other_account = create(:account)
        other_role = create(:coop_core_staff_role, account: other_account)
        assignment = build(:coop_core_staff_role_assignment, account: account, staff_profile: staff_profile, staff_role: other_role)

        expect(assignment).not_to be_valid
      end
    end

    context 'when the account does not match the branch account' do
      it 'is invalid' do
        other_account = create(:account)
        other_branch = create(:coop_core_branch, account: other_account)
        assignment = build(:coop_core_staff_role_assignment, account: account, staff_profile: staff_profile, staff_role: staff_role,
                                                             branch: other_branch)

        expect(assignment).not_to be_valid
      end
    end
  end

  describe 'auditing' do
    it 'is audited' do
      expect(described_class.auditing_enabled).to be true
    end
  end
end
