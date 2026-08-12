# Manual producer<->contact linking (design §8.3, S5). Auto-linking runs via
# CoopCoreListener + CoopCore::LinkProducerJob; this is the explicit override
# an operator uses when the automatic phone/CUIT match misses or was wrong.
# Nested under a producer (`resource :contact_link`, no `:id` param -- see
# routes.rb) so authorization/lookup keys off params[:producer_id], not the
# show/update/destroy :id convention BaseController's #coop_record assumes.
class Api::V1::Accounts::Coop::ContactLinksController < Api::V1::Accounts::Coop::BaseController
  self.coop_module = :producers
  self.coop_resource_class = ::CoopCore::Producer

  def create
    @producer = coop_record
    contact = Current.account.contacts.find(params[:contact_id])

    return render_conflict(I18n.t('coop_core.errors.producer_already_linked')) if producer_already_linked_elsewhere?(contact)

    if @producer.link_contact(contact)
      render 'api/v1/accounts/coop/producers/show'
    else
      render_conflict(I18n.t('coop_core.errors.contact_already_linked'))
    end
  end

  def destroy
    @producer = coop_record
    @producer.unlink_contact

    render 'api/v1/accounts/coop/producers/show'
  end

  private

  def producer_already_linked_elsewhere?(contact)
    @producer.contact_id.present? && @producer.contact_id != contact.id
  end

  def render_conflict(message)
    render json: { error: message }, status: :unprocessable_entity
  end

  # Nested singleton resource keyed by :producer_id, not :id -- BaseController's
  # default #coop_record assumes the show/update/destroy :id convention, which
  # doesn't apply to this `resource :contact_link` route (design §3.2, S4b
  # lesson: verify route param names, don't assume the design doc's file tree).
  def coop_record
    @coop_record ||= coop_scope.find(params[:producer_id])
  end
end
