# frozen_string_literal: true

require 'rails_helper'

# Role x resource authorization matrix for CoopCore::BasePolicy (design §7.3
# bootstrap rule / §7.4 base policy). Exercised through concrete subclasses
# (ProducerPolicy, FieldPolicy) since BasePolicy itself is abstract
# (read_permission/manage_permission raise NotImplementedError).
RSpec.describe CoopCore::BasePolicy, type: :policy do
  let(:account) { create(:account) }

  def context_for(user)
    { user: user, account: account, account_user: account.account_users.find_by!(user: user) }
  end

  describe 'administrator bootstrap rule (design §7.3)' do
    let(:administrator) { create(:user, account: account, role: :administrator) }
    let(:producer) { create(:coop_core_producer, account: account) }

    it 'grants index? with no staff profile at all' do
      policy = CoopCore::ProducerPolicy.new(context_for(administrator), CoopCore::Producer)

      expect(policy.index?).to be true
    end

    it 'grants create? with no staff profile at all' do
      policy = CoopCore::ProducerPolicy.new(context_for(administrator), CoopCore::Producer)

      expect(policy.create?).to be true
    end

    it 'grants show? on a record from the account' do
      policy = CoopCore::ProducerPolicy.new(context_for(administrator), producer)

      expect(policy.show?).to be true
    end
  end

  describe 'a role-based operador profile (read-only)' do
    let(:agent) { create(:user, account: account, role: :agent) }
    let(:operador_role) { create(:coop_core_staff_role, account: account, key: 'operador', permissions: ['producers_read']) }
    let!(:profile) { create(:coop_core_staff_profile, account: account, user: agent) }

    before { create(:coop_core_staff_role_assignment, account: account, staff_profile: profile, staff_role: operador_role) }

    it 'grants index?' do
      policy = CoopCore::ProducerPolicy.new(context_for(agent), CoopCore::Producer)

      expect(policy.index?).to be true
    end

    it 'grants show? on a record from the account' do
      producer = create(:coop_core_producer, account: account)
      policy = CoopCore::ProducerPolicy.new(context_for(agent), producer)

      expect(policy.show?).to be true
    end

    it 'denies create?' do
      policy = CoopCore::ProducerPolicy.new(context_for(agent), CoopCore::Producer)

      expect(policy.create?).to be false
    end
  end

  describe 'a role-based agronomo profile (manages agronomy resources, not producers)' do
    let(:agent) { create(:user, account: account, role: :agent) }
    let(:agronomo_role) do
      create(:coop_core_staff_role, account: account, key: 'agronomo',
                                    permissions: %w[fields_read fields_manage plots_manage crops_manage])
    end
    let!(:profile) { create(:coop_core_staff_profile, account: account, user: agent) }

    before { create(:coop_core_staff_role_assignment, account: account, staff_profile: profile, staff_role: agronomo_role) }

    it 'grants create? on fields' do
      policy = CoopCore::FieldPolicy.new(context_for(agent), CoopCore::Field)

      expect(policy.create?).to be true
    end

    it 'grants create? on plots' do
      policy = CoopCore::PlotPolicy.new(context_for(agent), CoopCore::Plot)

      expect(policy.create?).to be true
    end

    it 'grants create? on crops' do
      policy = CoopCore::CropPolicy.new(context_for(agent), CoopCore::Crop)

      expect(policy.create?).to be true
    end

    it 'denies create? on producers' do
      policy = CoopCore::ProducerPolicy.new(context_for(agent), CoopCore::Producer)

      expect(policy.create?).to be false
    end
  end

  describe 'an agent with no staff profile' do
    let(:agent) { create(:user, account: account, role: :agent) }
    let(:producer) { create(:coop_core_producer, account: account) }

    it 'denies index?' do
      policy = CoopCore::ProducerPolicy.new(context_for(agent), CoopCore::Producer)

      expect(policy.index?).to be false
    end

    it 'denies show?' do
      policy = CoopCore::ProducerPolicy.new(context_for(agent), producer)

      expect(policy.show?).to be false
    end

    it 'denies create?' do
      policy = CoopCore::ProducerPolicy.new(context_for(agent), CoopCore::Producer)

      expect(policy.create?).to be false
    end
  end

  describe 'an inactive staff profile' do
    let(:agent) { create(:user, account: account, role: :agent) }
    let(:role) { create(:coop_core_staff_role, account: account, permissions: ['producers_read']) }
    let!(:profile) { create(:coop_core_staff_profile, account: account, user: agent, active: false) }

    before { create(:coop_core_staff_role_assignment, account: account, staff_profile: profile, staff_role: role) }

    it 'denies index? despite the granted role permission' do
      policy = CoopCore::ProducerPolicy.new(context_for(agent), CoopCore::Producer)

      expect(policy.index?).to be false
    end
  end

  describe 'CoopCore::AuditLogPolicy (audit_read, design §7.1/§9)' do
    let(:administrator) { create(:user, account: account, role: :administrator) }
    let(:agent) { create(:user, account: account, role: :agent) }

    it 'grants index? to an administrator with no staff profile' do
      policy = CoopCore::AuditLogPolicy.new(context_for(administrator), CoopCore::AuditLog)

      expect(policy.index?).to be true
    end

    it 'denies index? to an agent with no staff profile' do
      policy = CoopCore::AuditLogPolicy.new(context_for(agent), CoopCore::AuditLog)

      expect(policy.index?).to be false
    end

    context 'when the agent has a staff profile with audit_read' do
      let(:role) { create(:coop_core_staff_role, account: account, permissions: ['audit_read']) }
      let!(:profile) { create(:coop_core_staff_profile, account: account, user: agent) }

      before { create(:coop_core_staff_role_assignment, account: account, staff_profile: profile, staff_role: role) }

      it 'grants index?' do
        policy = CoopCore::AuditLogPolicy.new(context_for(agent), CoopCore::AuditLog)

        expect(policy.index?).to be true
      end
    end
  end

  describe 'CoopCore::EventSubscriptionPolicy (modules_manage, design §7.1)' do
    let(:administrator) { create(:user, account: account, role: :administrator) }
    let(:agent) { create(:user, account: account, role: :agent) }

    it 'grants index? to an administrator with no staff profile' do
      policy = CoopCore::EventSubscriptionPolicy.new(context_for(administrator), CoopCore::EventSubscription)

      expect(policy.index?).to be true
    end

    it 'denies index? to an agent with no staff profile' do
      policy = CoopCore::EventSubscriptionPolicy.new(context_for(agent), CoopCore::EventSubscription)

      expect(policy.index?).to be false
    end

    it 'denies create? to a profile that only has modules_read' do
      role = create(:coop_core_staff_role, account: account, permissions: ['modules_read'])
      profile = create(:coop_core_staff_profile, account: account, user: agent)
      create(:coop_core_staff_role_assignment, account: account, staff_profile: profile, staff_role: role)

      policy = CoopCore::EventSubscriptionPolicy.new(context_for(agent), CoopCore::EventSubscription)

      expect(policy.create?).to be false
    end

    context 'when the agent has a staff profile with modules_manage' do
      let(:role) { create(:coop_core_staff_role, account: account, permissions: ['modules_manage']) }
      let!(:profile) { create(:coop_core_staff_profile, account: account, user: agent) }

      before { create(:coop_core_staff_role_assignment, account: account, staff_profile: profile, staff_role: role) }

      it 'grants create?' do
        policy = CoopCore::EventSubscriptionPolicy.new(context_for(agent), CoopCore::EventSubscription)

        expect(policy.create?).to be true
      end
    end
  end

  describe 'CoopCore::ProducerPolicy#export? (export_data, design §7.1)' do
    let(:administrator) { create(:user, account: account, role: :administrator) }
    let(:agent) { create(:user, account: account, role: :agent) }

    it 'grants export? to an administrator' do
      policy = CoopCore::ProducerPolicy.new(context_for(administrator), CoopCore::Producer)

      expect(policy.export?).to be true
    end

    it 'denies export? to an agent with no staff profile' do
      policy = CoopCore::ProducerPolicy.new(context_for(agent), CoopCore::Producer)

      expect(policy.export?).to be false
    end

    it 'denies export? to a profile that only has producers_manage' do
      role = create(:coop_core_staff_role, account: account, permissions: ['producers_manage'])
      profile = create(:coop_core_staff_profile, account: account, user: agent)
      create(:coop_core_staff_role_assignment, account: account, staff_profile: profile, staff_role: role)

      policy = CoopCore::ProducerPolicy.new(context_for(agent), CoopCore::Producer)

      expect(policy.export?).to be false
    end

    context 'when the agent has a staff profile with export_data' do
      let(:role) { create(:coop_core_staff_role, account: account, permissions: ['export_data']) }
      let!(:profile) { create(:coop_core_staff_profile, account: account, user: agent) }

      before { create(:coop_core_staff_role_assignment, account: account, staff_profile: profile, staff_role: role) }

      it 'grants export?' do
        policy = CoopCore::ProducerPolicy.new(context_for(agent), CoopCore::Producer)

        expect(policy.export?).to be true
      end
    end
  end

  describe 'CoopCore::BasePolicy::Scope branch filtering (design §7.4)' do
    let(:agent) { create(:user, account: account, role: :agent) }
    let(:administrator) { create(:user, account: account, role: :administrator) }
    let(:branch_a) { create(:coop_core_branch, account: account) }
    let(:branch_b) { create(:coop_core_branch, account: account) }
    let!(:producer_in_branch_a) { create(:coop_core_producer, account: account, branch: branch_a) }
    let!(:producer_in_branch_b) { create(:coop_core_producer, account: account, branch: branch_b) }
    let!(:producer_with_no_branch) { create(:coop_core_producer, account: account) }

    context 'when the profile is assigned to a single branch' do
      let!(:profile) { create(:coop_core_staff_profile, account: account, user: agent) }
      let(:role) { create(:coop_core_staff_role, account: account) }

      before { create(:coop_core_staff_role_assignment, account: account, staff_profile: profile, staff_role: role, branch: branch_a) }

      it 'includes producers from the assigned branch' do
        resolved = CoopCore::ProducerPolicy::Scope.new(context_for(agent), CoopCore::Producer).resolve

        expect(resolved).to include(producer_in_branch_a)
      end

      it 'includes cooperative-wide (NULL branch) producers' do
        resolved = CoopCore::ProducerPolicy::Scope.new(context_for(agent), CoopCore::Producer).resolve

        expect(resolved).to include(producer_with_no_branch)
      end

      it 'excludes producers from a different branch' do
        resolved = CoopCore::ProducerPolicy::Scope.new(context_for(agent), CoopCore::Producer).resolve

        expect(resolved).not_to include(producer_in_branch_b)
      end
    end

    context 'when the profile has only cooperative-wide (NULL branch) role assignments' do
      let!(:profile) { create(:coop_core_staff_profile, account: account, user: agent) }
      let(:role) { create(:coop_core_staff_role, account: account) }

      before { create(:coop_core_staff_role_assignment, account: account, staff_profile: profile, staff_role: role, branch: nil) }

      it 'includes producers from every branch' do
        resolved = CoopCore::ProducerPolicy::Scope.new(context_for(agent), CoopCore::Producer).resolve

        expect(resolved).to contain_exactly(producer_in_branch_a, producer_in_branch_b, producer_with_no_branch)
      end
    end

    context 'when the user is an administrator' do
      it 'includes producers from every branch regardless of any staff profile' do
        resolved = CoopCore::ProducerPolicy::Scope.new(context_for(administrator), CoopCore::Producer).resolve

        expect(resolved).to contain_exactly(producer_in_branch_a, producer_in_branch_b, producer_with_no_branch)
      end
    end

    # CoopCore::Field carries its own branch_id (design §4/Domain 4) --
    # locks in that CoopCore::FieldPolicy::Scope goes through the same
    # branch_filtered logic as ProducerPolicy::Scope above rather than only
    # ever being exercised via CoopCore::Producer.
    context 'when a CoopCore::FieldPolicy::Scope profile is assigned to a single branch' do
      let!(:profile) { create(:coop_core_staff_profile, account: account, user: agent) }
      let(:role) { create(:coop_core_staff_role, account: account, permissions: ['fields_read']) }
      let!(:field_in_branch_a) { create(:coop_core_field, account: account, branch: branch_a) }
      let!(:field_in_branch_b) { create(:coop_core_field, account: account, branch: branch_b) }
      let!(:field_with_no_branch) { create(:coop_core_field, account: account) }

      before { create(:coop_core_staff_role_assignment, account: account, staff_profile: profile, staff_role: role, branch: branch_a) }

      it 'includes fields from the assigned branch' do
        resolved = CoopCore::FieldPolicy::Scope.new(context_for(agent), CoopCore::Field).resolve

        expect(resolved).to include(field_in_branch_a)
      end

      it 'includes cooperative-wide (NULL branch) fields' do
        resolved = CoopCore::FieldPolicy::Scope.new(context_for(agent), CoopCore::Field).resolve

        expect(resolved).to include(field_with_no_branch)
      end

      it 'excludes fields from a different branch' do
        resolved = CoopCore::FieldPolicy::Scope.new(context_for(agent), CoopCore::Field).resolve

        expect(resolved).not_to include(field_in_branch_b)
      end
    end
  end
end
