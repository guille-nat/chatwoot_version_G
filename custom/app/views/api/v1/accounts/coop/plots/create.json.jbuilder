json.payload do
  json.partial! 'api/v1/coop/models/plot', formats: [:json], resource: @plot
end
