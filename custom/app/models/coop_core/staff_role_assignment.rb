# Join row between a CoopCore::StaffProfile and a CoopCore::StaffRole,
# optionally scoped to a CoopCore::Branch (design §4/§7). A NULL branch_id
# means the assignment applies cooperative-wide -- CoopCore::BasePolicy::Scope
# treats it as visible from every branch (branch_filtered).
class CoopCore::StaffRoleAssignment < CoopCore::ApplicationRecord
  include CoopCore::AccountScoped

  belongs_to :staff_profile, class_name: 'CoopCore::StaffProfile', inverse_of: :role_assignments
  belongs_to :staff_role, class_name: 'CoopCore::StaffRole', inverse_of: :role_assignments
  belongs_to :branch, class_name: 'CoopCore::Branch', optional: true

  validates :staff_role_id, uniqueness: { scope: %i[staff_profile_id branch_id] }
  validate :account_matches_staff_profile
  validate :account_matches_staff_role
  validate :account_matches_branch

  private

  def account_matches_staff_profile
    return if staff_profile.blank? || account_id.blank?

    errors.add(:staff_profile, :invalid) if staff_profile.account_id != account_id
  end

  def account_matches_staff_role
    return if staff_role.blank? || account_id.blank?

    errors.add(:staff_role, :invalid) if staff_role.account_id != account_id
  end

  def account_matches_branch
    return if branch.blank? || account_id.blank?

    errors.add(:branch, :invalid) if branch.account_id != account_id
  end
end
