class Api::V1::Accounts::Conversations::HistoryController < Api::V1::Accounts::Conversations::BaseController
  # GET /api/v1/accounts/:account_id/conversations/:conversation_id/history
  #
  # Returns messages from other conversations of the same contact+inbox ("sibling
  # conversations"), cursor-paginated via before_id so the UI can lazy-load older
  # history with infinite scroll upward.
  #
  # When the inbox has lock_to_single_conversation enabled the endpoint always
  # returns an empty payload so the UI shows no cross-conversation history.
  def index
    if @conversation.inbox.lock_to_single_conversation
      render json: { meta: { contact_id: @conversation.contact_id, has_more: false }, payload: [] }
      return
    end

    sibling_ids = sibling_conversation_ids
    if sibling_ids.empty?
      render json: { meta: { contact_id: @conversation.contact_id, has_more: false }, payload: [] }
      return
    end

    @limit = params[:limit].to_i.positive? ? params[:limit].to_i : 50

    cursor_id = if params[:before_id].present?
                  params[:before_id].to_i
                else
                  oldest_cursor
                end

    fetched = Current.account.messages
                     .where(conversation_id: sibling_ids)
                     .where('id < ?', cursor_id)
                     .includes(:attachments, :sender, :conversation,
                               sender: { avatar_attachment: [:blob] })
                     .order(id: :desc)
                     .limit(@limit)

    @has_more = fetched.length == @limit
    # Reverse so the payload arrives oldest-first (matches existing message API shape)
    @history_messages = fetched.to_a.reverse
  end

  private

  def sibling_conversation_ids
    Current.account.conversations
           .where(contact_id: @conversation.contact_id, inbox_id: @conversation.inbox_id)
           .where.not(id: @conversation.id)
           .pluck(:id)
  end

  def oldest_cursor
    @conversation.messages.order(:id).pick(:id) || ((Message.maximum(:id) || 0) + 1)
  end
end
