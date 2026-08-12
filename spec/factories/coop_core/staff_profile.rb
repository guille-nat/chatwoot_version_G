FactoryBot.define do
  factory :coop_core_staff_profile, class: 'CoopCore::StaffProfile' do
    account
    user { create(:user, account: account) }
  end
end
