FactoryBot.define do
  factory :coop_core_field, class: 'CoopCore::Field' do
    account
    producer { association :coop_core_producer, account: account }
    sequence(:name) { |n| "Campo #{n}" }
  end
end
