# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Coop Conversation Producer API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:contact) { create(:contact, account: account) }
  let(:conversation) { create(:conversation, account: account, contact: contact) }

  describe 'GET /api/v1/accounts/{account.id}/coop/conversations/{conversation.display_id}/producer' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/coop/conversations/#{conversation.display_id}/producer"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when the conversation contact has a linked producer' do
      let!(:producer) { create(:coop_core_producer, account: account, contact_id: contact.id) }

      it 'returns the linked producer' do
        get "/api/v1/accounts/#{account.id}/coop/conversations/#{conversation.display_id}/producer",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(response.parsed_body['payload']['id']).to eq(producer.id)
      end
    end

    context 'when the conversation contact has no linked producer' do
      it 'returns not found' do
        get "/api/v1/accounts/#{account.id}/coop/conversations/#{conversation.display_id}/producer",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when the conversation belongs to another account' do
      it 'returns not found' do
        other_account = create(:account)
        other_conversation = create(:conversation, account: other_account)

        get "/api/v1/accounts/#{account.id}/coop/conversations/#{other_conversation.display_id}/producer",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when it is a regular agent' do
      it 'returns unauthorized' do
        agent = create(:user, account: account, role: :agent)

        get "/api/v1/accounts/#{account.id}/coop/conversations/#{conversation.display_id}/producer",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when the producers module is disabled for the account' do
      before do
        CoopCore::Feature.set_account_override(:producers, account: account, enabled: false)
      end

      it 'returns forbidden' do
        get "/api/v1/accounts/#{account.id}/coop/conversations/#{conversation.display_id}/producer",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
