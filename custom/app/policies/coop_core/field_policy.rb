# fields_read / fields_manage (design §7.1) -- real permission checks
# (administrator bootstrap + staff_profile) live in CoopCore::BasePolicy (S6).
class CoopCore::FieldPolicy < CoopCore::BasePolicy
  private

  def read_permission
    :fields_read
  end

  def manage_permission
    :fields_manage
  end
end
