json.payload do
  json.array! @plots do |plot|
    json.partial! 'api/v1/coop/models/plot', formats: [:json], resource: plot
  end
end
