json.payload do
  json.array! @crops do |crop|
    json.partial! 'api/v1/coop/models/crop', formats: [:json], resource: crop
  end
end
