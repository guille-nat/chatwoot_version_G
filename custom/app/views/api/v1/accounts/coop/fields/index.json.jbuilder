json.payload do
  json.array! @fields do |field|
    json.partial! 'api/v1/coop/models/field', formats: [:json], resource: field
  end
end
