json.payload do
  json.array! @event_subscriptions do |event_subscription|
    json.partial! 'api/v1/coop/models/event_subscription', formats: [:json], resource: event_subscription
  end
end
