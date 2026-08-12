json.payload do
  json.array! @staff_profiles do |staff_profile|
    json.partial! 'api/v1/coop/models/staff_profile', formats: [:json], resource: staff_profile
  end
end
