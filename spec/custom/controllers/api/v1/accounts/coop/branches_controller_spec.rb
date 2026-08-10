# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Coop Branches API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }

  describe 'GET /api/v1/accounts/{account.id}/coop/branches' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/coop/branches"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated administrator' do
      let!(:branch) { create(:coop_core_branch, account: account) }

      it 'returns the account branches' do
        get "/api/v1/accounts/#{account.id}/coop/branches",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(response.parsed_body['payload'].pluck('id')).to eq([branch.id])
      end

      it 'does not return branches from other accounts' do
        other_account = create(:account)
        create(:coop_core_branch, account: other_account, name: 'Other Account Branch')

        get "/api/v1/accounts/#{account.id}/coop/branches",
            headers: admin.create_new_auth_token,
            as: :json

        names = response.parsed_body['payload'].pluck('name')
        expect(names).not_to include('Other Account Branch')
      end

      it 'lists branches even when a spurious id query param is present' do
        get "/api/v1/accounts/#{account.id}/coop/branches",
            params: { id: 999_999 },
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(response.parsed_body['payload'].pluck('id')).to eq([branch.id])
      end
    end

    context 'when it is a regular agent' do
      it 'returns unauthorized' do
        agent = create(:user, account: account, role: :agent)

        get "/api/v1/accounts/#{account.id}/coop/branches",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/coop/branches/{id}' do
    let(:branch) { create(:coop_core_branch, account: account) }

    it 'returns the branch' do
      get "/api/v1/accounts/#{account.id}/coop/branches/#{branch.id}",
          headers: admin.create_new_auth_token,
          as: :json

      expect(response).to have_http_status(:success)
      expect(response.parsed_body['payload']['id']).to eq(branch.id)
    end

    it 'returns not found for a branch belonging to another account' do
      other_account = create(:account)
      other_branch = create(:coop_core_branch, account: other_account)

      get "/api/v1/accounts/#{account.id}/coop/branches/#{other_branch.id}",
          headers: admin.create_new_auth_token,
          as: :json

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/coop/branches' do
    let(:valid_params) do
      { branch: { name: 'Sucursal Rosario', code: 'RSR-01', kind: 'branch' } }
    end

    it 'creates a branch' do
      expect do
        post "/api/v1/accounts/#{account.id}/coop/branches",
             params: valid_params,
             headers: admin.create_new_auth_token,
             as: :json
      end.to change(CoopCore::Branch, :count).by(1)

      expect(response).to have_http_status(:success)
      expect(response.parsed_body['payload']['name']).to eq('Sucursal Rosario')
    end

    it 'returns unprocessable_entity for invalid params' do
      post "/api/v1/accounts/#{account.id}/coop/branches",
           params: { branch: { name: '' } },
           headers: admin.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'PATCH /api/v1/accounts/{account.id}/coop/branches/{id}' do
    let(:branch) { create(:coop_core_branch, account: account) }

    it 'updates the branch' do
      patch "/api/v1/accounts/#{account.id}/coop/branches/#{branch.id}",
            params: { branch: { name: 'Sucursal Actualizada' } },
            headers: admin.create_new_auth_token,
            as: :json

      expect(response).to have_http_status(:success)
      expect(response.parsed_body['payload']['name']).to eq('Sucursal Actualizada')
    end

    it 'returns not found when updating a branch from another account' do
      other_account = create(:account)
      other_branch = create(:coop_core_branch, account: other_account, name: 'Other Account Branch')

      patch "/api/v1/accounts/#{account.id}/coop/branches/#{other_branch.id}",
            params: { branch: { name: 'Hijack Attempt' } },
            headers: admin.create_new_auth_token,
            as: :json

      expect(response).to have_http_status(:not_found)
      expect(other_branch.reload.name).to eq('Other Account Branch')
    end
  end

  describe 'DELETE /api/v1/accounts/{account.id}/coop/branches/{id}' do
    it 'deletes the branch' do
      branch = create(:coop_core_branch, account: account)

      expect do
        delete "/api/v1/accounts/#{account.id}/coop/branches/#{branch.id}",
               headers: admin.create_new_auth_token,
               as: :json
      end.to change(CoopCore::Branch, :count).by(-1)

      expect(response).to have_http_status(:ok)
    end

    it 'returns not found when deleting a branch from another account' do
      other_account = create(:account)
      other_branch = create(:coop_core_branch, account: other_account)

      expect do
        delete "/api/v1/accounts/#{account.id}/coop/branches/#{other_branch.id}",
               headers: admin.create_new_auth_token,
               as: :json
      end.not_to change(CoopCore::Branch, :count)

      expect(response).to have_http_status(:not_found)
    end
  end
end
