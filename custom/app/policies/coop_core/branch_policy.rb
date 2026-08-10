# Real permission checks (staff_profile) land in S6; for now
# CoopCore::BasePolicy#permitted? grants Chatwoot account administrators
# only. read_permission/manage_permission are declared here so S6 has
# somewhere to plug in without touching this controller/policy pair again.
class CoopCore::BranchPolicy < CoopCore::BasePolicy
  private

  def read_permission
    :branches_read
  end

  def manage_permission
    :branches_manage
  end
end
