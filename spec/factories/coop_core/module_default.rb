FactoryBot.define do
  factory :coop_core_module_default, class: 'CoopCore::ModuleDefault' do
    sequence(:module_key) { |n| "module_#{n}" }
    enabled { false }
  end
end
