FactoryBot.define do
  factory :coop_core_module_setting, class: 'CoopCore::ModuleSetting' do
    account
    module_key { 'producers' }
    scope_type { 'account' }
    enabled { true }
  end
end
