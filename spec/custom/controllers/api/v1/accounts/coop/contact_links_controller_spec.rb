# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Coop Contact Links API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:producer) { create(:coop_core_producer, account: account) }
  let(:contact) { create(:contact, account: account) }

  describe 'POST /api/v1/accounts/{account.id}/coop/producers/{producer.id}/contact_link' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/api/v1/accounts/#{account.id}/coop/producers/#{producer.id}/contact_link",
             params: { contact_id: contact.id }

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated administrator' do
      it 'links the contact to the producer' do
        post "/api/v1/accounts/#{account.id}/coop/producers/#{producer.id}/contact_link",
             params: { contact_id: contact.id },
             headers: admin.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
        expect(producer.reload.contact_id).to eq(contact.id)
      end

      it 'returns the producer payload' do
        post "/api/v1/accounts/#{account.id}/coop/producers/#{producer.id}/contact_link",
             params: { contact_id: contact.id },
             headers: admin.create_new_auth_token,
             as: :json

        expect(response.parsed_body['payload']['contact_id']).to eq(contact.id)
      end

      it 'is idempotent when the producer is already linked to the same contact' do
        producer.update!(contact_id: contact.id)

        post "/api/v1/accounts/#{account.id}/coop/producers/#{producer.id}/contact_link",
             params: { contact_id: contact.id },
             headers: admin.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:success)
      end

      it 'returns unprocessable_entity when the producer is linked to a different contact' do
        other_contact = create(:contact, account: account)
        producer.update!(contact_id: other_contact.id)

        post "/api/v1/accounts/#{account.id}/coop/producers/#{producer.id}/contact_link",
             params: { contact_id: contact.id },
             headers: admin.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns unprocessable_entity when the contact is linked to a different producer' do
        create(:coop_core_producer, account: account, contact_id: contact.id)

        post "/api/v1/accounts/#{account.id}/coop/producers/#{producer.id}/contact_link",
             params: { contact_id: contact.id },
             headers: admin.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns not found when the contact belongs to another account' do
        other_account = create(:account)
        other_contact = create(:contact, account: other_account)

        post "/api/v1/accounts/#{account.id}/coop/producers/#{producer.id}/contact_link",
             params: { contact_id: other_contact.id },
             headers: admin.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:not_found)
      end

      it 'returns not found when the producer belongs to another account' do
        other_account = create(:account)
        other_producer = create(:coop_core_producer, account: other_account)

        post "/api/v1/accounts/#{account.id}/coop/producers/#{other_producer.id}/contact_link",
             params: { contact_id: contact.id },
             headers: admin.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when it is a regular agent' do
      it 'returns unauthorized' do
        agent = create(:user, account: account, role: :agent)

        post "/api/v1/accounts/#{account.id}/coop/producers/#{producer.id}/contact_link",
             params: { contact_id: contact.id },
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
        post "/api/v1/accounts/#{account.id}/coop/producers/#{producer.id}/contact_link",
             params: { contact_id: contact.id },
             headers: admin.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'DELETE /api/v1/accounts/{account.id}/coop/producers/{producer.id}/contact_link' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        delete "/api/v1/accounts/#{account.id}/coop/producers/#{producer.id}/contact_link"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated administrator' do
      it 'unlinks the contact' do
        producer.update!(contact_id: contact.id)

        delete "/api/v1/accounts/#{account.id}/coop/producers/#{producer.id}/contact_link",
               headers: admin.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:success)
        expect(producer.reload.contact_id).to be_nil
      end

      it 'is idempotent when the producer already has no contact linked' do
        delete "/api/v1/accounts/#{account.id}/coop/producers/#{producer.id}/contact_link",
               headers: admin.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:success)
      end

      it 'returns not found when the producer belongs to another account' do
        other_account = create(:account)
        other_producer = create(:coop_core_producer, account: other_account)

        delete "/api/v1/accounts/#{account.id}/coop/producers/#{other_producer.id}/contact_link",
               headers: admin.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when it is a regular agent' do
      it 'returns unauthorized' do
        agent = create(:user, account: account, role: :agent)

        delete "/api/v1/accounts/#{account.id}/coop/producers/#{producer.id}/contact_link",
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
        delete "/api/v1/accounts/#{account.id}/coop/producers/#{producer.id}/contact_link",
               headers: admin.create_new_auth_token,
               as: :json

        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
