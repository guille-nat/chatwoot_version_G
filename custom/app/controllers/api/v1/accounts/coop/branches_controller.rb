# CRUD for a cooperative's branches (sucursales). Branch is core platform
# infrastructure, not a licensable module -- coop_module stays false so the
# S3.8 module gate always treats it as enabled (design §4 "Branch depth in
# F1").
class Api::V1::Accounts::Coop::BranchesController < Api::V1::Accounts::Coop::BaseController
  self.coop_module = false
  self.coop_resource_class = ::CoopCore::Branch

  before_action :set_branch, only: [:show, :update, :destroy]

  def index
    @branches = coop_scope.order(:name)
  end

  def show; end

  def create
    @branch = Current.account.coop_branches.create!(branch_params)
  end

  def update
    @branch.update!(branch_params)
  end

  def destroy
    @branch.destroy!
    head :ok
  end

  private

  def set_branch
    @branch = coop_record
  end

  def branch_params
    params.require(:branch).permit(
      :name, :code, :kind, :address_line, :city, :province, :postal_code,
      :latitude, :longitude, :timezone, :active, settings: {}
    )
  end
end
