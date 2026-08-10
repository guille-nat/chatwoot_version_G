# Real permission checks (staff_profile) land in S6; for now
# CoopCore::BasePolicy#permitted? grants Chatwoot account administrators
# only -- see CoopCore::BranchPolicy for the same S1-era note.
class CoopCore::ModuleSettingPolicy < CoopCore::BasePolicy
  private

  def read_permission
    :modules_read
  end

  def manage_permission
    :modules_manage
  end
end
