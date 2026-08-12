# Real permission checks (staff_profile) land in S6; for now
# CoopCore::BasePolicy#permitted? grants Chatwoot account administrators
# only -- see CoopCore::ProducerPolicy for the same S4a-era note.
class CoopCore::CropPolicy < CoopCore::BasePolicy
  private

  def read_permission
    :crops_read
  end

  def manage_permission
    :crops_manage
  end
end
