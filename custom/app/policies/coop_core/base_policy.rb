# Deny-by-default base for every CoopCore::*Policy. Subclasses declare
# read_permission / manage_permission and get index?/show?/create?/update?/
# destroy? for free (design §7.4).
#
# Real permission checks (S6): a Chatwoot account administrator is a CoopFlow
# super-user inside their own account regardless of staff profile (design
# §7.3 bootstrap rule -- otherwise nobody could create the first profile).
# Everyone else is only as permitted as their active CoopCore::StaffProfile's
# assigned CoopCore::StaffRole permissions allow.
class CoopCore::BasePolicy < ApplicationPolicy
  def index?
    permitted?(read_permission)
  end

  def show?
    permitted?(read_permission) && scope.exists?(id: record.id)
  end

  def create?
    permitted?(manage_permission)
  end

  def update?
    create?
  end

  def destroy?
    create?
  end

  private

  def permitted?(permission)
    return false if account.blank?
    return true if account_user&.administrator?

    staff_profile&.permitted?(permission) || false
  end

  def staff_profile
    @staff_profile ||= ::CoopCore::StaffProfile.active.find_by(account_id: account.id, user_id: user&.id)
  end

  def read_permission
    raise NotImplementedError, "#{self.class} must implement #read_permission"
  end

  def manage_permission
    raise NotImplementedError, "#{self.class} must implement #manage_permission"
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      raise ::CoopCore::MissingAccountContext if account.blank?

      branch_filtered(scope.where(account_id: account.id))
    end

    private

    # Records with branch_id IS NULL are cooperative-wide and visible to
    # everyone (design §7.4) -- skipped entirely for models with no branch_id
    # column (e.g. CoopCore::Plot, CoopCore::Crop, CoopCore::StaffRole).
    def branch_filtered(relation)
      return relation unless relation.klass.column_names.include?('branch_id')

      ids = accessible_branch_ids
      return relation if ids == :all

      relation.where(branch_id: ids).or(relation.where(branch_id: nil))
    end

    # :all for administrators and for profiles whose role assignments ALL
    # have branch_id IS NULL (no scoped assignment at all, cooperative-wide by
    # construction); otherwise the distinct set of assigned branch ids.
    def accessible_branch_ids
      return :all if account_user&.administrator?

      profile = ::CoopCore::StaffProfile.active.find_by(account_id: account.id, user_id: user&.id)
      return [] if profile.blank?

      branch_ids = profile.role_assignments.pluck(:branch_id)
      return :all if branch_ids.all?(&:nil?)

      branch_ids.compact.uniq
    end
  end
end
