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

  # Review-fix (S6): branch_id used to be `on_delete: :nullify` on
  # coop_core_staff_role_assignments, same as producers/fields. But a NULL
  # branch_id on an assignment is already a meaningful, overloaded state --
  # "cooperative-wide by design" (CoopCore::BasePolicy::Scope). Nullifying a
  # branch-scoped assignment on branch deletion silently WIDENED that
  # profile's access from one branch to the whole cooperative. It must be
  # destroyed instead (on_delete: :cascade + Branch#staff_role_assignments
  # dependent: :destroy).
  describe 'destroying a branch with a branch-scoped staff role assignment' do
    let(:agent) { create(:user, account: account, role: :agent) }
    let(:branch_a) { create(:coop_core_branch, account: account) }
    let(:branch_b) { create(:coop_core_branch, account: account) }
    let!(:producer_in_branch_b) { create(:coop_core_producer, account: account, branch: branch_b) }
    let(:role) { create(:coop_core_staff_role, account: account) }
    let!(:profile) { create(:coop_core_staff_profile, account: account, user: agent) }
    let!(:assignment) do
      create(:coop_core_staff_role_assignment, account: account, staff_profile: profile, staff_role: role, branch: branch_a)
    end

    def context_for(user)
      { user: user, account: account, account_user: account.account_users.find_by!(user: user) }
    end

    it 'excludes the branch-B producer before branch A is destroyed (baseline)' do
      resolved = CoopCore::ProducerPolicy::Scope.new(context_for(agent), CoopCore::Producer).resolve

      expect(resolved).not_to include(producer_in_branch_b)
    end

    it 'destroys the branch-scoped assignment instead of nullifying it' do
      expect { branch_a.destroy! }.to change { CoopCore::StaffRoleAssignment.exists?(assignment.id) }.from(true).to(false)
    end

    it 'still excludes the branch-B producer after branch A is destroyed (does not widen to cooperative-wide access)' do
      branch_a.destroy!

      resolved = CoopCore::ProducerPolicy::Scope.new(context_for(agent), CoopCore::Producer).resolve

      expect(resolved).not_to include(producer_in_branch_b)
    end

    it 'destroys the branch when producers, fields and staff role assignments all reference it simultaneously' do
      producer_in_branch_a = create(:coop_core_producer, account: account, branch: branch_a)
      field_in_branch_a = create(:coop_core_field, account: account, branch: branch_a, producer: producer_in_branch_a)

      expect { branch_a.destroy! }.not_to raise_error

      aggregate_failures do
        expect(CoopCore::Producer.exists?(producer_in_branch_a.id)).to be true
        expect(producer_in_branch_a.reload.branch_id).to be_nil
        expect(CoopCore::Field.exists?(field_in_branch_a.id)).to be true
        expect(field_in_branch_a.reload.branch_id).to be_nil
        expect(CoopCore::StaffRoleAssignment.exists?(assignment.id)).to be false
      end
    end
  end
end
