json.payload do
  json.array! @branches do |branch|
    json.partial! 'api/v1/coop/models/branch', formats: [:json], resource: branch
  end
end
