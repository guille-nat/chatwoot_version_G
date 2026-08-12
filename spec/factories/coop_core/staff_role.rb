FactoryBot.define do
  factory :coop_core_staff_role, class: 'CoopCore::StaffRole' do
    account
    sequence(:key) { |n| "rol_#{n}" }
    sequence(:name) { |n| "Rol #{n}" }
    permissions { [] }
  end
end
