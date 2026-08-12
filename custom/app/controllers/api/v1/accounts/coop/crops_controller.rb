# CRUD for a plot's crops (cultivos). index/create are nested under a plot
# (design §3.2); show/update/destroy are flat member routes. Gated behind the
# same `producers` module as PlotsController -- crops belong to the producers
# domain, no separate coop_modules.yml entry.
class Api::V1::Accounts::Coop::CropsController < Api::V1::Accounts::Coop::BaseController
  self.coop_module = :producers
  self.coop_resource_class = ::CoopCore::Crop

  before_action :set_plot, only: [:index, :create]
  before_action :set_crop, only: [:show, :update, :destroy]

  def index
    @crops = @plot.crops.order(:campaign)
  end

  def show; end

  def create
    @crop = @plot.crops.create!(crop_params.merge(account_id: Current.account.id))
  end

  def update
    @crop.update!(crop_params)
  end

  def destroy
    @crop.destroy!
    head :ok
  end

  private

  # Account-scoped, not a bare CoopCore::Plot.find -- a plot_id from another
  # account must 404, never leak crop data (design §10.3).
  def set_plot
    @plot = ::CoopCore::Plot.where(account_id: Current.account.id).find(params[:plot_id])
  end

  def set_crop
    @crop = coop_record
  end

  def crop_params
    params.require(:crop).permit(
      :species, :variety, :campaign, :sowing_date, :harvest_date,
      :hectares, :expected_yield_kg_per_ha, :status
    )
  end
end
