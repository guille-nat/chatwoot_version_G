json.payload do
  json.partial! 'api/v1/coop/models/crop', formats: [:json], resource: @crop
end
