json.payload do
  json.array! @modules do |definition|
    json.partial! 'api/v1/coop/models/module', formats: [:json], resource: definition, features: @features
  end
end
