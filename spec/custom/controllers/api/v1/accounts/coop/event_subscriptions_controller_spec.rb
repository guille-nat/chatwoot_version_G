# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Coop Event Subscriptions API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }

  describe 'GET /api/v1/accounts/{account.id}/coop/event_subscriptions' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/coop/event_subscriptions"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is a regular agent with no staff profile' do
      it 'returns unauthorized' do
        agent = create(:user, account: account, role: :agent)

        get "/api/v1/accounts/#{account.id}/coop/event_subscriptions",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated administrator' do
      let!(:subscription) { create(:coop_core_event_subscription, account: account) }

      it 'returns the account event subscriptions' do
        get "/api/v1/accounts/#{account.id}/coop/event_subscriptions",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(response.parsed_body['payload'].pluck('id')).to eq([subscription.id])
      end

      it 'does not include the secret in the response' do
        get "/api/v1/accounts/#{account.id}/coop/event_subscriptions",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response.body).not_to include(subscription.secret)
      end

      it 'does not return event subscriptions from another account' do
        other_account = create(:account)
        create(:coop_core_event_subscription, account: other_account, url: 'https://other.example.com/hook')

        get "/api/v1/accounts/#{account.id}/coop/event_subscriptions",
            headers: admin.create_new_auth_token,
            as: :json

        urls = response.parsed_body['payload'].pluck('url')
        expect(urls).not_to include('https://other.example.com/hook')
      end
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/coop/event_subscriptions/{id}' do
    let(:subscription) { create(:coop_core_event_subscription, account: account) }

    it 'returns not found for a subscription belonging to another account' do
      other_account = create(:account)
      other_subscription = create(:coop_core_event_subscription, account: other_account)

      get "/api/v1/accounts/#{account.id}/coop/event_subscriptions/#{other_subscription.id}",
          headers: admin.create_new_auth_token,
          as: :json

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/coop/event_subscriptions' do
    let(:valid_params) do
      { event_subscription: { url: 'https://example.com/coopflow', event_keys: ['producer_created'] } }
    end

    it 'creates an event subscription' do
      expect do
        post "/api/v1/accounts/#{account.id}/coop/event_subscriptions",
             params: valid_params,
             headers: admin.create_new_auth_token,
             as: :json
      end.to change(CoopCore::EventSubscription, :count).by(1)

      expect(response).to have_http_status(:success)
    end

    it 'does not include the secret in the response' do
      post "/api/v1/accounts/#{account.id}/coop/event_subscriptions",
           params: valid_params,
           headers: admin.create_new_auth_token,
           as: :json

      expect(response.parsed_body['payload']).not_to have_key('secret')
    end

    it 'returns unprocessable_entity for an invalid url' do
      post "/api/v1/accounts/#{account.id}/coop/event_subscriptions",
           params: { event_subscription: { url: 'not-a-url' } },
           headers: admin.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'returns unauthorized for a regular agent with no staff profile' do
      agent = create(:user, account: account, role: :agent)

      post "/api/v1/accounts/#{account.id}/coop/event_subscriptions",
           params: valid_params,
           headers: agent.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'PATCH /api/v1/accounts/{account.id}/coop/event_subscriptions/{id}' do
    let(:subscription) { create(:coop_core_event_subscription, account: account) }

    it 'updates the event subscription' do
      patch "/api/v1/accounts/#{account.id}/coop/event_subscriptions/#{subscription.id}",
            params: { event_subscription: { active: false } },
            headers: admin.create_new_auth_token,
            as: :json

      expect(response.parsed_body['payload']['active']).to be false
    end
  end

  describe 'DELETE /api/v1/accounts/{account.id}/coop/event_subscriptions/{id}' do
    it 'deletes the event subscription' do
      subscription = create(:coop_core_event_subscription, account: account)

      expect do
        delete "/api/v1/accounts/#{account.id}/coop/event_subscriptions/#{subscription.id}",
               headers: admin.create_new_auth_token,
               as: :json
      end.to change(CoopCore::EventSubscription, :count).by(-1)

      expect(response).to have_http_status(:ok)
    end
  end
end
