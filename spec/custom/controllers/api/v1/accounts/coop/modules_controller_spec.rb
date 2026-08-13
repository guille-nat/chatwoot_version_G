# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Coop Modules API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }

  describe 'GET /api/v1/accounts/{account.id}/coop/modules' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/coop/modules"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is a regular agent' do
      it 'returns unauthorized' do
        agent = create(:user, account: account, role: :agent)

        get "/api/v1/accounts/#{account.id}/coop/modules", headers: agent.create_new_auth_token, as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated administrator' do
      it 'includes a module enabled by its code default' do
        get "/api/v1/accounts/#{account.id}/coop/modules", headers: admin.create_new_auth_token, as: :json

        producers = response.parsed_body['payload'].find { |entry| entry['key'] == 'producers' }
        expect(producers['enabled']).to be true
      end

      it 'includes a module disabled by its code default' do
        get "/api/v1/accounts/#{account.id}/coop/modules", headers: admin.create_new_auth_token, as: :json

        market = response.parsed_body['payload'].find { |entry| entry['key'] == 'market' }
        expect(market['enabled']).to be false
      end

      it 'serializes each module dependency list from the registry' do
        get "/api/v1/accounts/#{account.id}/coop/modules", headers: admin.create_new_auth_token, as: :json

        payload = response.parsed_body['payload']
        producers = payload.find { |entry| entry['key'] == 'producers' }
        requests = payload.find { |entry| entry['key'] == 'requests' }

        expect(producers['depends_on']).to eq([])
        expect(requests['depends_on']).to eq(['producers'])
      end

      it 'does not reflect another account module setting' do
        other_account = create(:account)
        create(:coop_core_module_setting, account: other_account, module_key: 'market', scope_type: 'account', enabled: true)

        get "/api/v1/accounts/#{account.id}/coop/modules", headers: admin.create_new_auth_token, as: :json

        market = response.parsed_body['payload'].find { |entry| entry['key'] == 'market' }
        expect(market['enabled']).to be false
      end

      it 'returns the account-canonical state instead of the acting admin personal override' do
        create(:coop_core_module_setting, account: account, module_key: 'market', scope_type: 'user', scope_id: admin.id, enabled: true)

        get "/api/v1/accounts/#{account.id}/coop/modules", headers: admin.create_new_auth_token, as: :json

        market = response.parsed_body['payload'].find { |entry| entry['key'] == 'market' }
        expect(market['enabled']).to be false
      end
    end
  end

  describe 'PATCH /api/v1/accounts/{account.id}/coop/modules/{key}' do
    context 'when it is a regular agent' do
      it 'returns unauthorized' do
        agent = create(:user, account: account, role: :agent)

        patch "/api/v1/accounts/#{account.id}/coop/modules/market",
              params: { enabled: true },
              headers: agent.create_new_auth_token,
              as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated administrator' do
      it 'creates an account-scope module setting' do
        expect do
          patch "/api/v1/accounts/#{account.id}/coop/modules/market",
                params: { enabled: true },
                headers: admin.create_new_auth_token,
                as: :json
        end.to change(CoopCore::ModuleSetting, :count).by(1)
      end

      it 'enables the module for subsequent resolution' do
        patch "/api/v1/accounts/#{account.id}/coop/modules/market",
              params: { enabled: true },
              headers: admin.create_new_auth_token,
              as: :json

        market = response.parsed_body['payload'].find { |entry| entry['key'] == 'market' }
        expect(market['enabled']).to be true
      end

      it 'reuses the existing row on a second toggle instead of duplicating it' do
        patch "/api/v1/accounts/#{account.id}/coop/modules/market",
              params: { enabled: true },
              headers: admin.create_new_auth_token,
              as: :json

        expect do
          patch "/api/v1/accounts/#{account.id}/coop/modules/market",
                params: { enabled: false },
                headers: admin.create_new_auth_token,
                as: :json
        end.not_to change(CoopCore::ModuleSetting, :count)
      end

      it 'returns not found for an unknown module key' do
        patch "/api/v1/accounts/#{account.id}/coop/modules/not_a_real_module",
              params: { enabled: true },
              headers: admin.create_new_auth_token,
              as: :json

        expect(response).to have_http_status(:not_found)
      end

      it 'does not affect another account module setting' do
        other_account = create(:account)

        patch "/api/v1/accounts/#{account.id}/coop/modules/market",
              params: { enabled: true },
              headers: admin.create_new_auth_token,
              as: :json

        expect(CoopCore::Feature.enabled?(:market, account: other_account)).to be false
      end

      it 'shows the dependency cascade in the response payload' do
        patch "/api/v1/accounts/#{account.id}/coop/modules/requests",
              params: { enabled: true },
              headers: admin.create_new_auth_token,
              as: :json

        patch "/api/v1/accounts/#{account.id}/coop/modules/producers",
              params: { enabled: false },
              headers: admin.create_new_auth_token,
              as: :json

        requests = response.parsed_body['payload'].find { |entry| entry['key'] == 'requests' }
        expect(requests['enabled']).to be false
      end

      it 'returns the account-canonical state instead of the acting admin personal override' do
        create(:coop_core_module_setting, account: account, module_key: 'market', scope_type: 'user', scope_id: admin.id, enabled: true)

        patch "/api/v1/accounts/#{account.id}/coop/modules/weather",
              params: { enabled: true },
              headers: admin.create_new_auth_token,
              as: :json

        market = response.parsed_body['payload'].find { |entry| entry['key'] == 'market' }
        expect(market['enabled']).to be false
      end
    end
  end
end
