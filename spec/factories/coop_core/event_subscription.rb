FactoryBot.define do
  factory :coop_core_event_subscription, class: 'CoopCore::EventSubscription' do
    account
    url { 'https://example.com/coopflow/webhook' }
  end
end
