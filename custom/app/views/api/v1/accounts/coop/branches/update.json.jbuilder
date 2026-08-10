json.payload do
  json.partial! 'api/v1/coop/models/branch', formats: [:json], resource: @branch
end
