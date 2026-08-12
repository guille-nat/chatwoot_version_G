# crops_read / crops_manage (design §7.1) -- real permission checks
# (administrator bootstrap + staff_profile) live in CoopCore::BasePolicy (S6).
class CoopCore::CropPolicy < CoopCore::BasePolicy
  private

  def read_permission
    :crops_read
  end

  def manage_permission
    :crops_manage
  end
end
