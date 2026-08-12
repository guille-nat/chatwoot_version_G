# CRUD for a cooperative's staff profiles (perfiles de staff). Staff profiles
# are core platform infrastructure (authorization, not a licensable module)
# -- coop_module stays false, same as StaffRolesController.
class Api::V1::Accounts::Coop::StaffProfilesController < Api::V1::Accounts::Coop::BaseController
  self.coop_module = false
  self.coop_resource_class = ::CoopCore::StaffProfile

  before_action :set_staff_profile, only: [:show, :update, :destroy]

  def index
    @staff_profiles = coop_scope.order(:id)
  end

  def show; end

  def create
    @staff_profile = Current.account.coop_staff_profiles.create!(staff_profile_params)
  end

  def update
    @staff_profile.update!(staff_profile_params)
  end

  def destroy
    @staff_profile.destroy!
    head :ok
  end

  private

  def set_staff_profile
    @staff_profile = coop_record
  end

  def staff_profile_params
    params.require(:staff_profile).permit(
      :user_id, :default_branch_id, :active, beta_groups: [],
                                             role_assignments_attributes: [:id, :staff_role_id, :branch_id, :_destroy]
    )
  end
end
