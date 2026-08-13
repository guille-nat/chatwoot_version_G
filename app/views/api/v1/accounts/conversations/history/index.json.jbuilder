json.meta do
  json.contact_id @conversation.contact_id
  json.has_more @has_more
  json.next_before_id @history_messages.first&.id
end

json.payload do
  json.array! @history_messages do |message|
    json.partial! 'api/v1/models/message', message: message
  end
end
