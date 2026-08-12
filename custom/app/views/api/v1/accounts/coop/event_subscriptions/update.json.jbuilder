json.payload do
  json.partial! 'api/v1/coop/models/event_subscription', formats: [:json], resource: @event_subscription
end
