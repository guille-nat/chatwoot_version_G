# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Coop Plots API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:producer) { create(:coop_core_producer, account: account) }
  let(:field) { create(:coop_core_field, account: account, producer: producer) }

  describe 'GET /api/v1/accounts/{account.id}/coop/fields/{field.id}/plots' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/coop/fields/#{field.id}/plots"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated administrator' do
      let!(:plot) { create(:coop_core_plot, account: account, field: field) }

      it 'returns the field plots' do
        get "/api/v1/accounts/#{account.id}/coop/fields/#{field.id}/plots",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
        expect(response.parsed_body['payload'].pluck('id')).to eq([plot.id])
      end

      it 'returns not found for a field belonging to another account' do
        other_account = create(:account)
        other_producer = create(:coop_core_producer, account: other_account)
        other_field = create(:coop_core_field, account: other_account, producer: other_producer)

        get "/api/v1/accounts/#{account.id}/coop/fields/#{other_field.id}/plots",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when it is a regular agent' do
      it 'returns unauthorized' do
        agent = create(:user, account: account, role: :agent)

        get "/api/v1/accounts/#{account.id}/coop/fields/#{field.id}/plots",
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
        get "/api/v1/accounts/#{account.id}/coop/fields/#{field.id}/plots",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:forbidden)
      end

      it 'renders the module_disabled error_code' do
        get "/api/v1/accounts/#{account.id}/coop/fields/#{field.id}/plots",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response.parsed_body['error_code']).to eq('module_disabled')
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/coop/fields/{field.id}/plots' do
    let(:polygon) do
      { type: 'Polygon', coordinates: [[[-60.0, -33.0], [-60.1, -33.0], [-60.1, -33.1], [-60.0, -33.0]]] }
    end
    let(:valid_params) do
      { plot: { name: 'Lote 1', hectares: 45.75, geometry: polygon } }
    end

    it 'creates a plot under the field' do
      expect do
        post "/api/v1/accounts/#{account.id}/coop/fields/#{field.id}/plots",
             params: valid_params,
             headers: admin.create_new_auth_token,
             as: :json
      end.to change(CoopCore::Plot, :count).by(1)

      expect(response).to have_http_status(:success)
      expect(response.parsed_body['payload']['name']).to eq('Lote 1')
    end

    it 'stores the submitted geometry' do
      post "/api/v1/accounts/#{account.id}/coop/fields/#{field.id}/plots",
           params: valid_params,
           headers: admin.create_new_auth_token,
           as: :json

      expect(response.parsed_body['payload']['geometry']['type']).to eq('Polygon')
    end

    it 'returns unprocessable_entity for a missing name' do
      post "/api/v1/accounts/#{account.id}/coop/fields/#{field.id}/plots",
           params: { plot: { name: '' } },
           headers: admin.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'returns not found when the field belongs to another account' do
      other_account = create(:account)
      other_producer = create(:coop_core_producer, account: other_account)
      other_field = create(:coop_core_field, account: other_account, producer: other_producer)

      post "/api/v1/accounts/#{account.id}/coop/fields/#{other_field.id}/plots",
           params: valid_params,
           headers: admin.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/coop/plots/{id}' do
    it 'returns the plot' do
      plot = create(:coop_core_plot, account: account, field: field)

      get "/api/v1/accounts/#{account.id}/coop/plots/#{plot.id}",
          headers: admin.create_new_auth_token,
          as: :json

      expect(response).to have_http_status(:success)
      expect(response.parsed_body['payload']['id']).to eq(plot.id)
    end

    it 'returns not found for a plot belonging to another account' do
      other_account = create(:account)
      other_producer = create(:coop_core_producer, account: other_account)
      other_field = create(:coop_core_field, account: other_account, producer: other_producer)
      other_plot = create(:coop_core_plot, account: other_account, field: other_field)

      get "/api/v1/accounts/#{account.id}/coop/plots/#{other_plot.id}",
          headers: admin.create_new_auth_token,
          as: :json

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'PATCH /api/v1/accounts/{account.id}/coop/plots/{id}' do
    it 'updates the plot' do
      plot = create(:coop_core_plot, account: account, field: field)

      patch "/api/v1/accounts/#{account.id}/coop/plots/#{plot.id}",
            params: { plot: { name: 'Lote Actualizado' } },
            headers: admin.create_new_auth_token,
            as: :json

      expect(response).to have_http_status(:success)
      expect(response.parsed_body['payload']['name']).to eq('Lote Actualizado')
    end

    it 'returns not found when updating a plot from another account' do
      other_account = create(:account)
      other_producer = create(:coop_core_producer, account: other_account)
      other_field = create(:coop_core_field, account: other_account, producer: other_producer)
      other_plot = create(:coop_core_plot, account: other_account, field: other_field, name: 'Other Account Plot')

      patch "/api/v1/accounts/#{account.id}/coop/plots/#{other_plot.id}",
            params: { plot: { name: 'Hijack Attempt' } },
            headers: admin.create_new_auth_token,
            as: :json

      expect(response).to have_http_status(:not_found)
      expect(other_plot.reload.name).to eq('Other Account Plot')
    end
  end

  describe 'DELETE /api/v1/accounts/{account.id}/coop/plots/{id}' do
    it 'deletes the plot' do
      plot = create(:coop_core_plot, account: account, field: field)

      expect do
        delete "/api/v1/accounts/#{account.id}/coop/plots/#{plot.id}",
               headers: admin.create_new_auth_token,
               as: :json
      end.to change(CoopCore::Plot, :count).by(-1)

      expect(response).to have_http_status(:ok)
    end

    it 'returns not found when deleting a plot from another account' do
      other_account = create(:account)
      other_producer = create(:coop_core_producer, account: other_account)
      other_field = create(:coop_core_field, account: other_account, producer: other_producer)
      other_plot = create(:coop_core_plot, account: other_account, field: other_field)

      expect do
        delete "/api/v1/accounts/#{account.id}/coop/plots/#{other_plot.id}",
               headers: admin.create_new_auth_token,
               as: :json
      end.not_to change(CoopCore::Plot, :count)

      expect(response).to have_http_status(:not_found)
    end
  end
end
