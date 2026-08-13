json.meta do
  json.labels @conversation.cached_label_list_array
  json.additional_attributes @conversation.additional_attributes
  json.contact @conversation.contact.push_event_data
  json.assignee @conversation.assignee.push_event_data if @conversation.assignee.present?
  json.agent_last_seen_at @conversation.agent_last_seen_at
  json.assignee_last_seen_at @conversation.assignee_last_seen_at
  # Pagination indicator: true when there are more messages to load above the current window.
  # messages_before and messages_latest use limit 20; messages_after uses limit 100.
  page_size = params[:before].present? || params[:after].blank? ? 20 : 100
  json.has_more @messages.length >= page_size
end

json.payload do
  json.array! @messages do |message|
    json.partial! 'api/v1/models/message', message: message
  end
end
