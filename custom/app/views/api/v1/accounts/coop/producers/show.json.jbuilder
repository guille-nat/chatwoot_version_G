json.payload do
  json.partial! 'api/v1/coop/models/producer', formats: [:json], resource: @producer
end
