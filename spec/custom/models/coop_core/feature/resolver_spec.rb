# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CoopCore::Feature::Resolver, type: :model do
  subject(:resolver) do
    described_class.new(account: account, user: user, branch: branch, beta_groups: beta_groups, staff_role_ids: staff_role_ids)
  end

  let(:account) { create(:account) }
  let(:user) { nil }
  let(:branch) { nil }
  let(:beta_groups) { nil }
  let(:staff_role_ids) { nil }

  describe '#enabled?' do
    context 'when no override exists for a module' do
      it 'falls back to the code default for an opt-in-by-default module' do
        expect(resolver.enabled?(:producers)).to be true
      end

      it 'falls back to the code default for an opt-out-by-default module' do
        expect(resolver.enabled?(:market)).to be false
      end
    end

    context 'with an account-scope override' do
      it 'enables a module the code defaults to off' do
        create(:coop_core_module_setting, account: account, module_key: 'market', scope_type: 'account', enabled: true)

        expect(resolver.enabled?(:market)).to be true
      end

      it 'disables a module the code defaults to on' do
        create(:coop_core_module_setting, account: account, module_key: 'producers', scope_type: 'account', enabled: false)

        expect(resolver.enabled?(:producers)).to be false
      end
    end

    context 'with a branch-scope override' do
      let(:branch) { create(:coop_core_branch, account: account) }

      it 'beats the account-scope override' do
        create(:coop_core_module_setting, account: account, module_key: 'market', scope_type: 'account', enabled: false)
        create(:coop_core_module_setting, account: account, module_key: 'market', scope_type: 'branch', scope_id: branch.id, enabled: true)

        expect(resolver.enabled?(:market)).to be true
      end

      it 'does not apply to a different branch' do
        other_branch = create(:coop_core_branch, account: account)
        create(:coop_core_module_setting, account: account, module_key: 'market', scope_type: 'branch', scope_id: other_branch.id, enabled: true)

        expect(resolver.enabled?(:market)).to be false
      end
    end

    context 'with a staff_role-scope override' do
      it 'beats the branch-scope override' do
        branch = create(:coop_core_branch, account: account)
        create(:coop_core_module_setting, account: account, module_key: 'market', scope_type: 'branch', scope_id: branch.id, enabled: false)
        create(:coop_core_module_setting, account: account, module_key: 'market', scope_type: 'staff_role', scope_id: 42, enabled: true)
        resolver_with_role = described_class.new(account: account, branch: branch, staff_role_ids: [42])

        expect(resolver_with_role.enabled?(:market)).to be true
      end
    end

    context 'with a beta_group-scope override' do
      it 'beats the staff_role-scope override' do
        create(:coop_core_module_setting, account: account, module_key: 'market', scope_type: 'staff_role', scope_id: 1, enabled: false)
        create(:coop_core_module_setting, account: account, module_key: 'market', scope_type: 'beta_group', scope_key: 'pilot', enabled: true)
        resolver_with_beta = described_class.new(account: account, beta_groups: ['pilot'], staff_role_ids: [1])

        expect(resolver_with_beta.enabled?(:market)).to be true
      end
    end

    # S6 wiring: derived_staff_profile was a no-op stub until CoopCore::
    # StaffProfile existed (S1-S5). No resolver code changed to make these
    # pass -- `defined?(::CoopCore::StaffProfile)` is now true and the
    # existing lookup wires itself up automatically.
    context 'with a real StaffProfile granting a beta_group membership (tier 2)' do
      let(:staff_user) { create(:user, account: account) }

      before { create(:coop_core_staff_profile, account: account, user: staff_user, beta_groups: ['pilot']) }

      it 'resolves an enabled beta_group override without passing beta_groups explicitly' do
        create(:coop_core_module_setting, account: account, module_key: 'market', scope_type: 'beta_group', scope_key: 'pilot', enabled: true)

        resolver_for_staff_user = described_class.new(account: account, user: staff_user)

        expect(resolver_for_staff_user.enabled?(:market)).to be true
      end
    end

    context 'with a real StaffProfile holding a staff role assignment (tier 3)' do
      let(:staff_user) { create(:user, account: account) }
      let(:role) { create(:coop_core_staff_role, account: account) }

      before do
        profile = create(:coop_core_staff_profile, account: account, user: staff_user)
        create(:coop_core_staff_role_assignment, account: account, staff_profile: profile, staff_role: role)
      end

      it 'resolves an enabled staff_role override without passing staff_role_ids explicitly' do
        create(:coop_core_module_setting, account: account, module_key: 'market', scope_type: 'staff_role', scope_id: role.id, enabled: true)

        resolver_for_staff_user = described_class.new(account: account, user: staff_user)

        expect(resolver_for_staff_user.enabled?(:market)).to be true
      end
    end

    context 'with a user-scope override' do
      it 'beats the beta_group-scope override' do
        member = create(:user, account: account)
        create(:coop_core_module_setting, account: account, module_key: 'market', scope_type: 'beta_group', scope_key: 'pilot', enabled: false)
        create(:coop_core_module_setting, account: account, module_key: 'market', scope_type: 'user', scope_id: member.id, enabled: true)
        resolver_with_user = described_class.new(account: account, user: member, beta_groups: ['pilot'])

        expect(resolver_with_user.enabled?(:market)).to be true
      end
    end

    context 'with an environment (installation) default' do
      it 'beats the code default' do
        create(:coop_core_module_default, module_key: 'market', enabled: true)

        expect(resolver.enabled?(:market)).to be true
      end

      it 'is beaten by an account-scope override' do
        create(:coop_core_module_default, module_key: 'market', enabled: true)
        create(:coop_core_module_setting, account: account, module_key: 'market', scope_type: 'account', enabled: false)

        expect(resolver.enabled?(:market)).to be false
      end
    end

    context 'when a tier has contradictory rows' do
      let(:beta_groups) { %w[pilot ops] }

      it 'resolves to disabled (fail-closed tie-break) when any matching row is disabled' do
        create(:coop_core_module_setting, account: account, module_key: 'market', scope_type: 'beta_group', scope_key: 'pilot', enabled: true)
        create(:coop_core_module_setting, account: account, module_key: 'market', scope_type: 'beta_group', scope_key: 'ops', enabled: false)

        expect(resolver.enabled?(:market)).to be false
      end
    end

    context 'with a dependency cascade' do
      it 'disables a module whose dependency is disabled' do
        create(:coop_core_module_setting, account: account, module_key: 'requests', scope_type: 'account', enabled: true)
        create(:coop_core_module_setting, account: account, module_key: 'producers', scope_type: 'account', enabled: false)

        expect(resolver.enabled?(:requests)).to be false
      end

      it 'enables a module once its dependency resolves enabled' do
        create(:coop_core_module_setting, account: account, module_key: 'requests', scope_type: 'account', enabled: true)

        expect(resolver.enabled?(:requests)).to be true
      end
    end

    context 'with the kill switch' do
      it 'forces a module disabled regardless of an explicit account enable' do
        create(:coop_core_module_setting, account: account, module_key: 'market', scope_type: 'account', enabled: true)

        with_modified_env COOP_DISABLED_MODULES: 'market' do
          expect(described_class.new(account: account).enabled?(:market)).to be false
        end
      end
    end

    context 'with an unknown module key' do
      it 'resolves to disabled instead of raising' do
        expect(resolver.enabled?(:not_a_real_module)).to be false
      end
    end

    context 'without an account' do
      it 'resolves to disabled' do
        expect(described_class.new(account: nil).enabled?(:producers)).to be false
      end
    end
  end

  describe '#enabled_keys' do
    it 'includes every module key that resolves enabled' do
      expect(resolver.enabled_keys).to include('producers')
    end

    it 'excludes every module key that resolves disabled' do
      expect(resolver.enabled_keys).not_to include('market')
    end
  end

  describe 'caching' do
    around do |example|
      original_cache = Rails.cache
      Rails.cache = ActiveSupport::Cache::MemoryStore.new
      example.run
      Rails.cache = original_cache
    end

    it 'expires the cached module settings after a write, so a fresh resolver sees the change' do
      expect(described_class.new(account: account).enabled?(:market)).to be false

      create(:coop_core_module_setting, account: account, module_key: 'market', scope_type: 'account', enabled: true)

      expect(described_class.new(account: account).enabled?(:market)).to be true
    end

    it 'expires the cached module defaults after a write, so a fresh resolver sees the change' do
      expect(described_class.new(account: account).enabled?(:market)).to be false

      create(:coop_core_module_default, module_key: 'market', enabled: true)

      expect(described_class.new(account: account).enabled?(:market)).to be true
    end
  end
end
