# modules_read / modules_manage (design §7.1) -- real permission checks
# (administrator bootstrap + staff_profile) live in CoopCore::BasePolicy (S6).
class CoopCore::ModuleSettingPolicy < CoopCore::BasePolicy
  private

  def read_permission
    :modules_read
  end

  def manage_permission
    :modules_manage
  end
end
