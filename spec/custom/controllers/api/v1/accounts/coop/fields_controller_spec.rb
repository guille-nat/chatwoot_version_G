# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Coop Fields API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:producer) { create(:coop_core_producer, account: account) }

  describe 'GET /api/v1/accounts/{account.id}/coop/producers/{producer.id}/fields' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/coop/producers/#{producer.id}/fields"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated administrator' do
      let!(:field) { create(:coop_core_field, account: account, producer: producer) }

      it 'returns the producer fields' do
        get "/api/v1/accounts/#{account.id}/coop/producers/#{producer.id}/fields",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(response.parsed_body['payload'].pluck('id')).to eq([field.id])
      end

      it 'returns not found for a producer belonging to another account' do
        other_account = create(:account)
        other_producer = create(:coop_core_producer, account: other_account)

        get "/api/v1/accounts/#{account.id}/coop/producers/#{other_producer.id}/fields",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when it is a regular agent' do
      it 'returns unauthorized' do
        agent = create(:user, account: account, role: :agent)

        get "/api/v1/accounts/#{account.id}/coop/producers/#{producer.id}/fields",
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
        get "/api/v1/accounts/#{account.id}/coop/producers/#{producer.id}/fields",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/coop/producers/{producer.id}/fields' do
    let(:valid_params) { { field: { name: 'Campo Norte', total_hectares: 120.5 } } }

    it 'creates a field under the producer' do
      expect do
        post "/api/v1/accounts/#{account.id}/coop/producers/#{producer.id}/fields",
             params: valid_params,
             headers: admin.create_new_auth_token,
             as: :json
      end.to change(CoopCore::Field, :count).by(1)

      expect(response).to have_http_status(:success)
      expect(response.parsed_body['payload']['name']).to eq('Campo Norte')
    end

    it 'returns unprocessable_entity for a missing name' do
      post "/api/v1/accounts/#{account.id}/coop/producers/#{producer.id}/fields",
           params: { field: { name: '' } },
           headers: admin.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'returns not found when the producer belongs to another account' do
      other_account = create(:account)
      other_producer = create(:coop_core_producer, account: other_account)

      post "/api/v1/accounts/#{account.id}/coop/producers/#{other_producer.id}/fields",
           params: valid_params,
           headers: admin.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:not_found)
    end

    it 'returns unprocessable_entity for a branch belonging to another account' do
      other_account = create(:account)
      other_branch = create(:coop_core_branch, account: other_account)

      post "/api/v1/accounts/#{account.id}/coop/producers/#{producer.id}/fields",
           params: { field: { name: 'Campo Norte', branch_id: other_branch.id } },
           headers: admin.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/coop/fields/{id}' do
    let(:field) { create(:coop_core_field, account: account, producer: producer) }

    it 'returns the field' do
      get "/api/v1/accounts/#{account.id}/coop/fields/#{field.id}",
          headers: admin.create_new_auth_token,
          as: :json

      expect(response).to have_http_status(:success)
      expect(response.parsed_body['payload']['id']).to eq(field.id)
    end

    it 'returns not found for a field belonging to another account' do
      other_account = create(:account)
      other_producer = create(:coop_core_producer, account: other_account)
      other_field = create(:coop_core_field, account: other_account, producer: other_producer)

      get "/api/v1/accounts/#{account.id}/coop/fields/#{other_field.id}",
          headers: admin.create_new_auth_token,
          as: :json

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'PATCH /api/v1/accounts/{account.id}/coop/fields/{id}' do
    let(:field) { create(:coop_core_field, account: account, producer: producer) }

    it 'updates the field' do
      patch "/api/v1/accounts/#{account.id}/coop/fields/#{field.id}",
            params: { field: { name: 'Campo Actualizado' } },
            headers: admin.create_new_auth_token,
            as: :json

      expect(response).to have_http_status(:success)
      expect(response.parsed_body['payload']['name']).to eq('Campo Actualizado')
    end

    it 'returns not found when updating a field from another account' do
      other_account = create(:account)
      other_producer = create(:coop_core_producer, account: other_account)
      other_field = create(:coop_core_field, account: other_account, producer: other_producer, name: 'Other Account Field')

      patch "/api/v1/accounts/#{account.id}/coop/fields/#{other_field.id}",
            params: { field: { name: 'Hijack Attempt' } },
            headers: admin.create_new_auth_token,
            as: :json

      expect(response).to have_http_status(:not_found)
      expect(other_field.reload.name).to eq('Other Account Field')
    end
  end

  describe 'DELETE /api/v1/accounts/{account.id}/coop/fields/{id}' do
    it 'deletes the field' do
      field = create(:coop_core_field, account: account, producer: producer)

      expect do
        delete "/api/v1/accounts/#{account.id}/coop/fields/#{field.id}",
               headers: admin.create_new_auth_token,
               as: :json
      end.to change(CoopCore::Field, :count).by(-1)

      expect(response).to have_http_status(:ok)
    end

    it 'returns not found when deleting a field from another account' do
      other_account = create(:account)
      other_producer = create(:coop_core_producer, account: other_account)
      other_field = create(:coop_core_field, account: other_account, producer: other_producer)

      expect do
        delete "/api/v1/accounts/#{account.id}/coop/fields/#{other_field.id}",
               headers: admin.create_new_auth_token,
               as: :json
      end.not_to change(CoopCore::Field, :count)

      expect(response).to have_http_status(:not_found)
    end
  end
end
