# CRUD for a field's plots (lotes). index/create are nested under a field
# (design §3.2); show/update/destroy are flat member routes. Gated behind the
# same `producers` module as FieldsController -- plots belong to the
# producers domain, no separate coop_modules.yml entry.
class Api::V1::Accounts::Coop::PlotsController < Api::V1::Accounts::Coop::BaseController
  self.coop_module = :producers
  self.coop_resource_class = ::CoopCore::Plot

  before_action :set_field, only: [:index, :create]
  before_action :set_plot, only: [:show, :update, :destroy]

  def index
    @plots = @field.plots.order(:name)
  end

  def show; end

  def create
    @plot = @field.plots.create!(plot_params.merge(account_id: Current.account.id))
  end

  def update
    @plot.update!(plot_params)
  end

  def destroy
    @plot.destroy!
    head :ok
  end

  private

  # Account-scoped, not a bare CoopCore::Field.find -- a field_id from
  # another account must 404, never leak plot data (design §10.3).
  def set_field
    @field = ::CoopCore::Field.where(account_id: Current.account.id).find(params[:field_id])
  end

  def set_plot
    @plot = coop_record
  end

  def plot_params
    params.require(:plot).permit(:name, :hectares, :soil_type, geometry: {})
  end
end
