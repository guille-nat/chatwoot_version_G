# CRUD for a cooperative's staff roles (roles de staff). Staff roles are core
# platform infrastructure (authorization, not a licensable module) --
# coop_module stays false, same as BranchesController/ModulesController.
class Api::V1::Accounts::Coop::StaffRolesController < Api::V1::Accounts::Coop::BaseController
  self.coop_module = false
  self.coop_resource_class = ::CoopCore::StaffRole

  before_action :set_staff_role, only: [:show, :update, :destroy]

  # Lazily ensures the six es-AR default roles (design §7.2) exist for this
  # account before listing them -- idempotent, never resets a role's
  # permissions once a cooperative has edited them.
  def index
    ::CoopCore::StaffRole.ensure_seeded!(Current.account)
    @staff_roles = coop_scope.order(:name)
  end

  def show; end

  def create
    @staff_role = Current.account.coop_staff_roles.create!(staff_role_params)
  end

  def update
    @staff_role.update!(staff_role_params)
  end

  # A system role's before_destroy guard aborts the save (not an exception),
  # so a failed #destroy is surfaced as the same 422 shape as a validation
  # failure -- render_record_invalid already renders that shape for any
  # ActiveRecord::RecordInvalid raised inside this action.
  def destroy
    @staff_role.destroy || raise(ActiveRecord::RecordInvalid, @staff_role)
    head :ok
  end

  private

  def set_staff_role
    @staff_role = coop_record
  end

  def staff_role_params
    params.require(:staff_role).permit(:key, :name, :description, permissions: [])
  end
end
