# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Coop Producers API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }

  describe 'GET /api/v1/accounts/{account.id}/coop/producers' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/coop/producers"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated administrator' do
      let!(:producer) { create(:coop_core_producer, account: account) }

      it 'returns the account producers' do
        get "/api/v1/accounts/#{account.id}/coop/producers",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(response.parsed_body['payload'].pluck('id')).to eq([producer.id])
      end

      it 'does not return producers from other accounts' do
        other_account = create(:account)
        create(:coop_core_producer, account: other_account, business_name: 'Other Account Producer')

        get "/api/v1/accounts/#{account.id}/coop/producers",
            headers: admin.create_new_auth_token,
            as: :json

        names = response.parsed_body['payload'].pluck('business_name')
        expect(names).not_to include('Other Account Producer')
      end
    end

    context 'when it is a regular agent' do
      it 'returns unauthorized' do
        agent = create(:user, account: account, role: :agent)

        get "/api/v1/accounts/#{account.id}/coop/producers",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when the producers module is disabled for the account' do
      # First real (non-`false`) coop_module gate exercised over real HTTP --
      # every prior controller (branches, modules) set coop_module = false.
      # spec/custom/controllers/coop_core/module_gated_spec.rb already covers
      # the concern's own rendering logic in isolation; this proves the full
      # request pipeline (registry -> resolver -> gate -> render) end to end.
      before do
        CoopCore::Feature.set_account_override(:producers, account: account, enabled: false)
      end

      it 'returns forbidden' do
        get "/api/v1/accounts/#{account.id}/coop/producers",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:forbidden)
      end

      it 'renders the module_disabled error_code' do
        get "/api/v1/accounts/#{account.id}/coop/producers",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response.parsed_body['error_code']).to eq('module_disabled')
      end
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/coop/producers/{id}' do
    let(:producer) { create(:coop_core_producer, account: account) }

    it 'returns the producer' do
      get "/api/v1/accounts/#{account.id}/coop/producers/#{producer.id}",
          headers: admin.create_new_auth_token,
          as: :json

      expect(response).to have_http_status(:success)
      expect(response.parsed_body['payload']['id']).to eq(producer.id)
    end

    it 'returns not found for a producer belonging to another account' do
      other_account = create(:account)
      other_producer = create(:coop_core_producer, account: other_account)

      get "/api/v1/accounts/#{account.id}/coop/producers/#{other_producer.id}",
          headers: admin.create_new_auth_token,
          as: :json

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/coop/producers' do
    let(:valid_params) do
      { producer: { business_name: 'Agropecuaria del Sur', cuit: '20-12345678-6' } }
    end

    it 'creates a producer' do
      expect do
        post "/api/v1/accounts/#{account.id}/coop/producers",
             params: valid_params,
             headers: admin.create_new_auth_token,
             as: :json
      end.to change(CoopCore::Producer, :count).by(1)

      expect(response).to have_http_status(:success)
      expect(response.parsed_body['payload']['business_name']).to eq('Agropecuaria del Sur')
    end

    it 'stores the normalized cuit' do
      post "/api/v1/accounts/#{account.id}/coop/producers",
           params: valid_params,
           headers: admin.create_new_auth_token,
           as: :json

      expect(response.parsed_body['payload']['cuit']).to eq('20123456786')
    end

    it 'renders the formatted cuit' do
      post "/api/v1/accounts/#{account.id}/coop/producers",
           params: valid_params,
           headers: admin.create_new_auth_token,
           as: :json

      expect(response.parsed_body['payload']['cuit_formatted']).to eq('20-12345678-6')
    end

    it 'returns unprocessable_entity for a missing business_name' do
      post "/api/v1/accounts/#{account.id}/coop/producers",
           params: { producer: { business_name: '' } },
           headers: admin.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'returns unprocessable_entity for a cuit with an invalid check digit' do
      post "/api/v1/accounts/#{account.id}/coop/producers",
           params: { producer: { business_name: 'Agropecuaria del Sur', cuit: '20-12345678-0' } },
           headers: admin.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'returns unprocessable_entity for a cuit with an unknown type prefix' do
      post "/api/v1/accounts/#{account.id}/coop/producers",
           params: { producer: { business_name: 'Agropecuaria del Sur', cuit: '99-12345678-3' } },
           headers: admin.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'allows the same cuit as a producer in a different cooperative' do
      other_account = create(:account)
      create(:coop_core_producer, account: other_account, cuit: '20-12345678-6')

      post "/api/v1/accounts/#{account.id}/coop/producers",
           params: valid_params,
           headers: admin.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:success)
    end

    it 'ignores a contact_id passed in the request params' do
      contact = create(:contact, account: account)

      post "/api/v1/accounts/#{account.id}/coop/producers",
           params: { producer: { business_name: 'Agropecuaria del Sur', contact_id: contact.id } },
           headers: admin.create_new_auth_token,
           as: :json

      expect(response.parsed_body['payload']['contact_id']).to be_nil
    end

    it 'returns unprocessable_entity for a branch belonging to another account' do
      other_account = create(:account)
      other_branch = create(:coop_core_branch, account: other_account)

      post "/api/v1/accounts/#{account.id}/coop/producers",
           params: { producer: { business_name: 'Agropecuaria del Sur', branch_id: other_branch.id } },
           headers: admin.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'PATCH /api/v1/accounts/{account.id}/coop/producers/{id}' do
    let(:producer) { create(:coop_core_producer, account: account) }

    it 'updates the producer' do
      patch "/api/v1/accounts/#{account.id}/coop/producers/#{producer.id}",
            params: { producer: { business_name: 'Nuevo Nombre' } },
            headers: admin.create_new_auth_token,
            as: :json

      expect(response).to have_http_status(:success)
      expect(response.parsed_body['payload']['business_name']).to eq('Nuevo Nombre')
    end

    it 'returns not found when updating a producer from another account' do
      other_account = create(:account)
      other_producer = create(:coop_core_producer, account: other_account, business_name: 'Other Account Producer')

      patch "/api/v1/accounts/#{account.id}/coop/producers/#{other_producer.id}",
            params: { producer: { business_name: 'Hijack Attempt' } },
            headers: admin.create_new_auth_token,
            as: :json

      expect(response).to have_http_status(:not_found)
      expect(other_producer.reload.business_name).to eq('Other Account Producer')
    end
  end

  describe 'DELETE /api/v1/accounts/{account.id}/coop/producers/{id}' do
    it 'deletes the producer' do
      producer = create(:coop_core_producer, account: account)

      expect do
        delete "/api/v1/accounts/#{account.id}/coop/producers/#{producer.id}",
               headers: admin.create_new_auth_token,
               as: :json
      end.to change(CoopCore::Producer, :count).by(-1)

      expect(response).to have_http_status(:ok)
    end

    it 'returns not found when deleting a producer from another account' do
      other_account = create(:account)
      other_producer = create(:coop_core_producer, account: other_account)

      expect do
        delete "/api/v1/accounts/#{account.id}/coop/producers/#{other_producer.id}",
               headers: admin.create_new_auth_token,
               as: :json
      end.not_to change(CoopCore::Producer, :count)

      expect(response).to have_http_status(:not_found)
    end
  end
end
