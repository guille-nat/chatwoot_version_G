# CRUD for a cooperative's producers (productores asociados). `producers` is
# the first real (non-`false`) coop_modules.yml key wired through this
# controller (design §5.1 -- default_enabled: true, licensable: false), so
# every request here exercises the full module gate pipeline for real.
#
# contact_id is intentionally NOT in producer_params: linking a producer to a
# contact is CoopCore::Producer::ContactLinkable's job (S5), reached only
# through the dedicated contact_link resource controller and its race-guarded
# partial unique index -- never through a bare producer create/update.
class Api::V1::Accounts::Coop::ProducersController < Api::V1::Accounts::Coop::BaseController
  self.coop_module = :producers
  self.coop_resource_class = ::CoopCore::Producer

  before_action :set_producer, only: [:show, :update, :destroy]

  def index
    @producers = coop_scope.order(:business_name)
  end

  def show; end

  def create
    @producer = Current.account.coop_producers.create!(producer_params)
  end

  def update
    @producer.update!(producer_params)
  end

  def destroy
    @producer.destroy!
    head :ok
  end

  private

  def set_producer
    @producer = coop_record
  end

  def producer_params
    params.require(:producer).permit(
      :business_name, :trade_name, :producer_type, :primary_phone, :email,
      :status, :cuit, :branch_id, :external_ref, :notes, custom_attributes: {}
    )
  end
end
