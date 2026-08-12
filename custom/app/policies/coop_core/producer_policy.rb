# producers_read / producers_manage (design §7.1) -- real permission checks
# (administrator bootstrap + staff_profile) live in CoopCore::BasePolicy (S6).
class CoopCore::ProducerPolicy < CoopCore::BasePolicy
  # export_data (design §7.1). Reached automatically: Pundit's `authorize`
  # defaults to "#{action_name}?" when no explicit query is given, and
  # Api::V1::Accounts::Coop::BaseController#authorize_coop_resource calls
  # exactly that -- ProducersController#export needs no bespoke
  # authorize(..., :export?) call of its own.
  def export?
    permitted?(:export_data)
  end

  private

  def read_permission
    :producers_read
  end

  def manage_permission
    :producers_manage
  end
end
