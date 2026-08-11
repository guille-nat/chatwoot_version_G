FactoryBot.define do
  factory :coop_core_producer, class: 'CoopCore::Producer' do
    account
    sequence(:business_name) { |n| "Productor #{n}" }
  end
end
