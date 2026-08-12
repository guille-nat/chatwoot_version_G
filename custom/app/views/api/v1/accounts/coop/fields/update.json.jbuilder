json.payload do
  json.partial! 'api/v1/coop/models/field', formats: [:json], resource: @field
end
