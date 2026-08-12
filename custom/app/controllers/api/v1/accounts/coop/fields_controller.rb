# CRUD for a producer's fields (campos). index/create are nested under a
# producer (design §3.2); show/update/destroy are flat member routes. Gated
# behind the same `producers` module as ProducersController (design §4 --
# fields belong to the producers domain, no separate coop_modules.yml entry).
class Api::V1::Accounts::Coop::FieldsController < Api::V1::Accounts::Coop::BaseController
  self.coop_module = :producers
  self.coop_resource_class = ::CoopCore::Field

  before_action :set_producer, only: [:index, :create]
  before_action :set_field, only: [:show, :update, :destroy]

  def index
    @fields = @producer.fields.order(:name)
  end

  def show; end

  def create
    @field = @producer.fields.create!(field_params.merge(account_id: Current.account.id))
  end

  def update
    @field.update!(field_params)
  end

  def destroy
    @field.destroy!
    head :ok
  end

  private

  # Account-scoped, not a bare CoopCore::Field.find -- a producer_id from
  # another account must 404, never leak field data (design §10.3).
  def set_producer
    @producer = Current.account.coop_producers.find(params[:producer_id])
  end

  def set_field
    @field = coop_record
  end

  def field_params
    params.require(:field).permit(
      :name, :branch_id, :total_hectares, :province, :locality,
      :latitude, :longitude, :external_ref, custom_attributes: {}
    )
  end
end
