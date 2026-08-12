json.id resource.id
json.user_id resource.user_id
json.default_branch_id resource.default_branch_id
json.beta_groups resource.beta_groups
json.active resource.active
json.role_assignments resource.role_assignments do |assignment|
  json.id assignment.id
  json.staff_role_id assignment.staff_role_id
  json.branch_id assignment.branch_id
end
json.created_at resource.created_at.to_i
json.updated_at resource.updated_at.to_i
