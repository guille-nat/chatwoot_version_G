# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Coop Staff Roles API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }

  describe 'GET /api/v1/accounts/{account.id}/coop/staff_roles' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/coop/staff_roles"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated administrator' do
      it 'seeds and returns the six default staff roles' do
        get "/api/v1/accounts/#{account.id}/coop/staff_roles",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response.parsed_body['payload'].pluck('key')).to match_array(
          %w[gerente administracion comercial agronomo logistica operador]
        )
      end

      it 'does not return staff roles from other accounts' do
        other_account = create(:account)
        create(:coop_core_staff_role, account: other_account, key: 'custom_role')

        get "/api/v1/accounts/#{account.id}/coop/staff_roles",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response.parsed_body['payload'].pluck('key')).not_to include('custom_role')
      end
    end

    context 'when it is a regular agent with no staff profile' do
      it 'returns unauthorized' do
        agent = create(:user, account: account, role: :agent)

        get "/api/v1/accounts/#{account.id}/coop/staff_roles",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/coop/staff_roles/{id}' do
    let(:staff_role) { create(:coop_core_staff_role, account: account) }

    it 'returns the staff role' do
      get "/api/v1/accounts/#{account.id}/coop/staff_roles/#{staff_role.id}",
          headers: admin.create_new_auth_token,
          as: :json

      expect(response.parsed_body['payload']['id']).to eq(staff_role.id)
    end

    it 'returns not found for a staff role belonging to another account' do
      other_account = create(:account)
      other_role = create(:coop_core_staff_role, account: other_account)

      get "/api/v1/accounts/#{account.id}/coop/staff_roles/#{other_role.id}",
          headers: admin.create_new_auth_token,
          as: :json

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/coop/staff_roles' do
    let(:valid_params) do
      { staff_role: { key: 'ventas', name: 'Ventas', permissions: ['producers_read'] } }
    end

    it 'creates a staff role' do
      expect do
        post "/api/v1/accounts/#{account.id}/coop/staff_roles",
             params: valid_params,
             headers: admin.create_new_auth_token,
             as: :json
      end.to change(CoopCore::StaffRole, :count).by(1)

      expect(response).to have_http_status(:success)
    end

    it 'returns unprocessable_entity for an unknown permission' do
      post "/api/v1/accounts/#{account.id}/coop/staff_roles",
           params: { staff_role: { key: 'ventas', name: 'Ventas', permissions: ['time_travel'] } },
           headers: admin.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'PATCH /api/v1/accounts/{account.id}/coop/staff_roles/{id}' do
    let(:staff_role) { create(:coop_core_staff_role, account: account, name: 'Original') }

    it 'updates the staff role' do
      patch "/api/v1/accounts/#{account.id}/coop/staff_roles/#{staff_role.id}",
            params: { staff_role: { name: 'Actualizado' } },
            headers: admin.create_new_auth_token,
            as: :json

      expect(response.parsed_body['payload']['name']).to eq('Actualizado')
    end

    it 'allows editing the permissions of a system role' do
      system_role = create(:coop_core_staff_role, account: account, system: true, permissions: ['producers_read'])

      patch "/api/v1/accounts/#{account.id}/coop/staff_roles/#{system_role.id}",
            params: { staff_role: { permissions: %w[producers_read producers_manage] } },
            headers: admin.create_new_auth_token,
            as: :json

      expect(response.parsed_body['payload']['permissions']).to match_array(%w[producers_read producers_manage])
    end
  end

  describe 'DELETE /api/v1/accounts/{account.id}/coop/staff_roles/{id}' do
    it 'deletes a non-system staff role' do
      staff_role = create(:coop_core_staff_role, account: account, system: false)

      expect do
        delete "/api/v1/accounts/#{account.id}/coop/staff_roles/#{staff_role.id}",
               headers: admin.create_new_auth_token,
               as: :json
      end.to change(CoopCore::StaffRole, :count).by(-1)

      expect(response).to have_http_status(:ok)
    end

    it 'returns unprocessable_entity for a system staff role' do
      staff_role = create(:coop_core_staff_role, account: account, system: true)

      delete "/api/v1/accounts/#{account.id}/coop/staff_roles/#{staff_role.id}",
             headers: admin.create_new_auth_token,
             as: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'does not delete a system staff role' do
      staff_role = create(:coop_core_staff_role, account: account, system: true)

      delete "/api/v1/accounts/#{account.id}/coop/staff_roles/#{staff_role.id}",
             headers: admin.create_new_auth_token,
             as: :json

      expect(CoopCore::StaffRole.exists?(staff_role.id)).to be true
    end

    it 'returns not found for a staff role belonging to another account' do
      other_account = create(:account)
      other_role = create(:coop_core_staff_role, account: other_account)

      expect do
        delete "/api/v1/accounts/#{account.id}/coop/staff_roles/#{other_role.id}",
               headers: admin.create_new_auth_token,
               as: :json
      end.not_to change(CoopCore::StaffRole, :count)

      expect(response).to have_http_status(:not_found)
    end
  end
end
