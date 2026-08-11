json.payload do
  json.array! @producers do |producer|
    json.partial! 'api/v1/coop/models/producer', formats: [:json], resource: producer
  end
end
