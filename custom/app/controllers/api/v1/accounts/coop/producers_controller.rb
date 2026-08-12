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

  # Synchronous export (design §13 S7 -- no exports table, no ActiveStorage,
  # no async job for F1), capped at ChatwootApp.max_limit and respecting the
  # same policy Scope (branch filtering) as #index. `export?` is reached
  # automatically -- see CoopCore::ProducerPolicy#export?.
  #
  # Format must be requested via the `.csv` / `.json` PATH extension, not a
  # `?format=` query param: custom/config/routes.rb sets
  # `defaults: { format: 'json' }` on the whole coop namespace, and Rails
  # only lets an incoming request override a routing *default* through the
  # actual path extension -- `request.parameters` is built as
  # `query_parameters.merge(path_parameters)` (path wins), so a query-string
  # `format` can never beat that namespace default. CSV is not the
  # wire-level default despite being this action's primary format; every
  # caller must pass an explicit extension.
  def export
    exporter = ::CoopCore::Export::ProducersCsv.new(export_scope)

    respond_to do |format|
      format.csv { send_data exporter.call, filename: export_filename('csv'), type: 'text/csv' }
      format.json { render json: exporter.rows }
    end
  end

  private

  def export_scope
    coop_scope.order(:business_name).limit(::ChatwootApp.max_limit)
  end

  def export_filename(extension)
    "productores-#{Current.account.id}-#{Time.current.strftime('%Y%m%d')}.#{extension}"
  end

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
