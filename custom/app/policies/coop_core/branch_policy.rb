# branches_read / branches_manage (design §7.1) -- real permission checks
# (administrator bootstrap + staff_profile) live in CoopCore::BasePolicy (S6).
class CoopCore::BranchPolicy < CoopCore::BasePolicy
  private

  def read_permission
    :branches_read
  end

  def manage_permission
    :branches_manage
  end
end
