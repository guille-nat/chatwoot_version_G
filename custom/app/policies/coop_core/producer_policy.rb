# producers_read / producers_manage (design §7.1) -- real permission checks
# (administrator bootstrap + staff_profile) live in CoopCore::BasePolicy (S6).
class CoopCore::ProducerPolicy < CoopCore::BasePolicy
  private

  def read_permission
    :producers_read
  end

  def manage_permission
    :producers_manage
  end
end
