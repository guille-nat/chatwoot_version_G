# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CoopCore::StaffProfile, type: :model do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }

  describe 'validations' do
    it 'is invalid without a user' do
      profile = build(:coop_core_staff_profile, account: account, user: nil)

      expect(profile).not_to be_valid
    end

    it 'is valid with only an account and a user' do
      profile = build(:coop_core_staff_profile, account: account, user: user)

      expect(profile).to be_valid
    end

    it 'is invalid with a duplicate user within the same account' do
      create(:coop_core_staff_profile, account: account, user: user)
      duplicate = build(:coop_core_staff_profile, account: account, user: user)

      expect(duplicate).not_to be_valid
    end

    context 'when the user does not belong to the account' do
      it 'is invalid' do
        outsider = create(:user)
        profile = build(:coop_core_staff_profile, account: account, user: outsider)

        expect(profile).not_to be_valid
      end
    end

    context 'when the default_branch account does not match the profile account' do
      it 'is invalid' do
        other_account = create(:account)
        other_branch = create(:coop_core_branch, account: other_account)
        profile = build(:coop_core_staff_profile, account: account, user: user, default_branch: other_branch)

        expect(profile).not_to be_valid
      end
    end

    it 'is valid when the default_branch account matches the profile account' do
      branch = create(:coop_core_branch, account: account)
      profile = build(:coop_core_staff_profile, account: account, user: user, default_branch: branch)

      expect(profile).to be_valid
    end
  end

  describe 'defaults' do
    it 'defaults active to true' do
      profile = described_class.new

      expect(profile.active).to be true
    end

    it 'defaults beta_groups to an empty array' do
      profile = described_class.new

      expect(profile.beta_groups).to eq([])
    end
  end

  describe '.active' do
    it 'includes active profiles' do
      profile = create(:coop_core_staff_profile, account: account, user: user, active: true)

      expect(described_class.active).to include(profile)
    end

    it 'excludes inactive profiles' do
      profile = create(:coop_core_staff_profile, account: account, user: user, active: false)

      expect(described_class.active).not_to include(profile)
    end
  end

  describe '#permitted?' do
    let(:profile) { create(:coop_core_staff_profile, account: account, user: user) }
    let(:role) { create(:coop_core_staff_role, account: account, permissions: ['producers_read']) }

    context 'when an assigned role grants the permission' do
      it 'returns true' do
        create(:coop_core_staff_role_assignment, account: account, staff_profile: profile, staff_role: role)

        expect(profile.permitted?('producers_read')).to be true
      end
    end

    context 'when no assigned role grants the permission' do
      it 'returns false' do
        create(:coop_core_staff_role_assignment, account: account, staff_profile: profile, staff_role: role)

        expect(profile.permitted?('producers_manage')).to be false
      end
    end

    context 'when the profile has no role assignments' do
      it 'returns false' do
        expect(profile.permitted?('producers_read')).to be false
      end
    end

    context 'when the profile is inactive' do
      it 'returns false even for a granted permission' do
        create(:coop_core_staff_role_assignment, account: account, staff_profile: profile, staff_role: role)
        profile.update!(active: false)

        expect(profile.permitted?('producers_read')).to be false
      end
    end
  end

  describe '#staff_role_ids' do
    it 'returns the ids of every assigned role' do
      profile = create(:coop_core_staff_profile, account: account, user: user)
      role = create(:coop_core_staff_role, account: account)
      create(:coop_core_staff_role_assignment, account: account, staff_profile: profile, staff_role: role)

      expect(profile.staff_role_ids).to eq([role.id])
    end
  end

  describe 'auditing' do
    it 'is audited' do
      expect(described_class.auditing_enabled).to be true
    end
  end
end
