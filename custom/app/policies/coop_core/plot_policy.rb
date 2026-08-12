# plots_read / plots_manage (design §7.1) -- real permission checks
# (administrator bootstrap + staff_profile) live in CoopCore::BasePolicy (S6).
class CoopCore::PlotPolicy < CoopCore::BasePolicy
  private

  def read_permission
    :plots_read
  end

  def manage_permission
    :plots_manage
  end
end
