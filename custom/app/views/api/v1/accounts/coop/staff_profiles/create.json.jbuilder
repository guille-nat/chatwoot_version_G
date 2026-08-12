json.payload do
  json.partial! 'api/v1/coop/models/staff_profile', formats: [:json], resource: @staff_profile
end
