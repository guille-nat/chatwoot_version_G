# staff_read / staff_manage (design §7.1) -- real permission checks
# (administrator bootstrap + staff_profile) live in CoopCore::BasePolicy (S6).
class CoopCore::StaffProfilePolicy < CoopCore::BasePolicy
  private

  def read_permission
    :staff_read
  end

  def manage_permission
    :staff_manage
  end
end
