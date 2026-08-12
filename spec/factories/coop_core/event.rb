FactoryBot.define do
  factory :coop_core_event, class: 'CoopCore::Event' do
    account
    sequence(:key) { |n| "test_event_#{n}" }
    payload { { foo: 'bar' } }
    occurred_at { Time.current }
    sequence(:idempotency_key) { |n| "test_event_#{n}:idempotency" }
  end
end
