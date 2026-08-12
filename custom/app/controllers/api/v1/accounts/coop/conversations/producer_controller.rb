# Shows the producer linked to a conversation's contact (design §3.2, S5).
# Read-only: linking itself only ever happens through ContactLinksController
# (manual) or CoopCore::LinkProducerJob (automatic).
class Api::V1::Accounts::Coop::Conversations::ProducerController < Api::V1::Accounts::Coop::BaseController
  self.coop_module = :producers
  self.coop_resource_class = ::CoopCore::Producer

  def show
    @producer = producer_for_conversation

    return render json: { error: I18n.t('coop_core.errors.producer_not_linked') }, status: :not_found if @producer.blank?

    render 'api/v1/accounts/coop/producers/show'
  end

  private

  # No single producer instance exists yet when the conversation's contact
  # isn't linked -- authorize against the resource class (mirrors index?,
  # which only checks the read permission) rather than BasePolicy#show?
  # (which assumes `record.id` on an actual instance).
  def coop_record
    coop_resource_class
  end

  def authorize_coop_resource
    authorize(coop_resource_class, :index?)
  end

  # Mirrors Chatwoot's own nested conversation endpoints
  # (Api::V1::Accounts::Conversations::BaseController#conversation):
  # conversation_id is the account-scoped display_id, never the raw PK.
  def conversation
    @conversation ||= Current.account.conversations.find_by!(display_id: params[:conversation_id])
  end

  def producer_for_conversation
    contact = conversation.contact
    return nil if contact.blank?

    coop_scope.find_by(contact_id: contact.id)
  end
end
