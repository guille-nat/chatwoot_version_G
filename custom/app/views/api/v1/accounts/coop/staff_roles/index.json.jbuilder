json.payload do
  json.array! @staff_roles do |staff_role|
    json.partial! 'api/v1/coop/models/staff_role', formats: [:json], resource: staff_role
  end
end
