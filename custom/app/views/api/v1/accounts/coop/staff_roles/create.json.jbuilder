json.payload do
  json.partial! 'api/v1/coop/models/staff_role', formats: [:json], resource: @staff_role
end
