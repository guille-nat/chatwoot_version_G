# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Coop Crops API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:producer) { create(:coop_core_producer, account: account) }
  let(:field) { create(:coop_core_field, account: account, producer: producer) }
  let(:plot) { create(:coop_core_plot, account: account, field: field) }

  describe 'GET /api/v1/accounts/{account.id}/coop/plots/{plot.id}/crops' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/coop/plots/#{plot.id}/crops"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated administrator' do
      let!(:crop) { create(:coop_core_crop, account: account, plot: plot) }

      it 'returns the plot crops' do
        get "/api/v1/accounts/#{account.id}/coop/plots/#{plot.id}/crops",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(response.parsed_body['payload'].pluck('id')).to eq([crop.id])
      end

      it 'returns not found for a plot belonging to another account' do
        other_account = create(:account)
        other_producer = create(:coop_core_producer, account: other_account)
        other_field = create(:coop_core_field, account: other_account, producer: other_producer)
        other_plot = create(:coop_core_plot, account: other_account, field: other_field)

        get "/api/v1/accounts/#{account.id}/coop/plots/#{other_plot.id}/crops",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/coop/plots/{plot.id}/crops' do
    let(:valid_params) { { crop: { species: 'soja', campaign: '2025/26', hectares: 30 } } }

    it 'creates a crop under the plot' do
      expect do
        post "/api/v1/accounts/#{account.id}/coop/plots/#{plot.id}/crops",
             params: valid_params,
             headers: admin.create_new_auth_token,
             as: :json
      end.to change(CoopCore::Crop, :count).by(1)

      expect(response).to have_http_status(:success)
      expect(response.parsed_body['payload']['species']).to eq('soja')
    end

    it 'returns unprocessable_entity for an unknown species' do
      post "/api/v1/accounts/#{account.id}/coop/plots/#{plot.id}/crops",
           params: { crop: { species: 'banana', campaign: '2025/26' } },
           headers: admin.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'returns unprocessable_entity for a malformed campaign' do
      post "/api/v1/accounts/#{account.id}/coop/plots/#{plot.id}/crops",
           params: { crop: { species: 'soja', campaign: '2025' } },
           headers: admin.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/coop/crops/{id}' do
    it 'returns the crop' do
      crop = create(:coop_core_crop, account: account, plot: plot)

      get "/api/v1/accounts/#{account.id}/coop/crops/#{crop.id}",
          headers: admin.create_new_auth_token,
          as: :json

      expect(response).to have_http_status(:success)
      expect(response.parsed_body['payload']['id']).to eq(crop.id)
    end

    it 'returns not found for a crop belonging to another account' do
      other_account = create(:account)
      other_producer = create(:coop_core_producer, account: other_account)
      other_field = create(:coop_core_field, account: other_account, producer: other_producer)
      other_plot = create(:coop_core_plot, account: other_account, field: other_field)
      other_crop = create(:coop_core_crop, account: other_account, plot: other_plot)

      get "/api/v1/accounts/#{account.id}/coop/crops/#{other_crop.id}",
          headers: admin.create_new_auth_token,
          as: :json

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'PATCH /api/v1/accounts/{account.id}/coop/crops/{id}' do
    it 'updates the crop' do
      crop = create(:coop_core_crop, account: account, plot: plot)

      patch "/api/v1/accounts/#{account.id}/coop/crops/#{crop.id}",
            params: { crop: { status: 'sown' } },
            headers: admin.create_new_auth_token,
            as: :json

      expect(response).to have_http_status(:success)
      expect(response.parsed_body['payload']['status']).to eq('sown')
    end
  end

  describe 'DELETE /api/v1/accounts/{account.id}/coop/crops/{id}' do
    it 'deletes the crop' do
      crop = create(:coop_core_crop, account: account, plot: plot)

      expect do
        delete "/api/v1/accounts/#{account.id}/coop/crops/#{crop.id}",
               headers: admin.create_new_auth_token,
               as: :json
      end.to change(CoopCore::Crop, :count).by(-1)

      expect(response).to have_http_status(:ok)
    end

    it 'returns not found when deleting a crop from another account' do
      other_account = create(:account)
      other_producer = create(:coop_core_producer, account: other_account)
      other_field = create(:coop_core_field, account: other_account, producer: other_producer)
      other_plot = create(:coop_core_plot, account: other_account, field: other_field)
      other_crop = create(:coop_core_crop, account: other_account, plot: other_plot)

      expect do
        delete "/api/v1/accounts/#{account.id}/coop/crops/#{other_crop.id}",
               headers: admin.create_new_auth_token,
               as: :json
      end.not_to change(CoopCore::Crop, :count)

      expect(response).to have_http_status(:not_found)
    end
  end
end
