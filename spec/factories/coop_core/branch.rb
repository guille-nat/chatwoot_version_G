FactoryBot.define do
  factory :coop_core_branch, class: 'CoopCore::Branch' do
    account
    sequence(:name) { |n| "Sucursal #{n}" }
  end
end
