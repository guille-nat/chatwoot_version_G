# Deny-by-default base for every CoopCore::*Policy. Subclasses declare
# read_permission / manage_permission and get index?/show?/create?/update?/destroy?
# for free. Real permission checks land in S6 -- staff_profile is not queryable
# yet in S1 (no coop_core_staff_profiles table), so permitted? currently only
# grants access to Chatwoot account administrators.
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

  def permitted?(_permission)
    return false if account.blank?

    account_user&.administrator? || false
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

      scope.where(account_id: account.id)
    end
  end
end
