FactoryBot.define do
  factory :coop_core_staff_role_assignment, class: 'CoopCore::StaffRoleAssignment' do
    account
    staff_profile { create(:coop_core_staff_profile, account: account) }
    staff_role { create(:coop_core_staff_role, account: account) }
  end
end
