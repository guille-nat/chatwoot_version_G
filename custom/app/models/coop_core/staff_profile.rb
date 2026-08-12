# A CoopFlow staff profile (perfil de staff) -- design §4/§7. Wraps a
# Chatwoot User with the CoopFlow-specific staff data (role assignments,
# default branch, beta group membership) needed for real permission checks
# (CoopCore::BasePolicy) and feature-flag resolution tiers 2-3
# (CoopCore::Feature::Resolver).
#
# `user` is intentionally NOT account-owned data -- users are shared
# Chatwoot infrastructure, not a CoopCore::AccountScoped model -- so instead
# of an account_matches_user guard this validates the user's membership via
# AccountUser (see #user_belongs_to_account).
class CoopCore::StaffProfile < CoopCore::ApplicationRecord
  include CoopCore::AccountScoped

  belongs_to :user
  belongs_to :default_branch, class_name: 'CoopCore::Branch', optional: true
  has_many :role_assignments, class_name: 'CoopCore::StaffRoleAssignment', dependent: :destroy,
                              inverse_of: :staff_profile
  has_many :staff_roles, through: :role_assignments

  # Nested-attributes shape chosen for the staff profile create/update API
  # (design: "accept staff_role_ids or assignments attributes -- pick the
  # simplest defensible shape"). `assignments attributes` was chosen over a
  # bare `staff_role_ids` array because branch-scoped assignment (design
  # §7.4 branch filtering) is a real feature of this slice -- a plain id
  # list could only ever express cooperative-wide (NULL branch) assignments.
  accepts_nested_attributes_for :role_assignments, allow_destroy: true

  validates :user_id, uniqueness: { scope: :account_id }
  validate :user_belongs_to_account
  validate :account_matches_default_branch

  before_validation :prepare_beta_groups

  scope :active, -> { where(active: true) }

  def permitted?(permission)
    return false unless active?

    staff_roles.any? { |role| role.permissions.include?(permission.to_s) }
  end

  def staff_role_ids
    role_assignments.pluck(:staff_role_id).uniq
  end

  private

  def prepare_beta_groups
    self.beta_groups = Array(beta_groups).compact.uniq
  end

  def user_belongs_to_account
    return if user_id.blank? || account_id.blank?

    errors.add(:user, :invalid) unless ::AccountUser.exists?(account_id: account_id, user_id: user_id)
  end

  def account_matches_default_branch
    return if default_branch.blank? || account_id.blank?

    errors.add(:default_branch, :invalid) if default_branch.account_id != account_id
  end
end
