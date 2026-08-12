# Real permission checks (staff_profile) land in S6; for now
# CoopCore::BasePolicy#permitted? grants Chatwoot account administrators
# only -- see CoopCore::ProducerPolicy for the same S4a-era note.
class CoopCore::FieldPolicy < CoopCore::BasePolicy
  private

  def read_permission
    :fields_read
  end

  def manage_permission
    :fields_manage
  end
end
