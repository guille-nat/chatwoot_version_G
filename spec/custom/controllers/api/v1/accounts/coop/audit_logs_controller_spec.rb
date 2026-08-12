# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Coop Audit Logs API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }

  describe 'GET /api/v1/accounts/{account.id}/coop/audit_logs' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/coop/audit_logs"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is a regular agent with no staff profile' do
      it 'returns unauthorized' do
        agent = create(:user, account: account, role: :agent)

        get "/api/v1/accounts/#{account.id}/coop/audit_logs",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated administrator' do
      it 'returns success' do
        get "/api/v1/accounts/#{account.id}/coop/audit_logs",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
      end

      it 'includes CoopCore audit rows' do
        producer = create(:coop_core_producer, account: account)
        producer.update!(business_name: 'Nombre Actualizado')
        team = create(:team, account: account)
        team.update!(name: 'Equipo Actualizado')

        get "/api/v1/accounts/#{account.id}/coop/audit_logs",
            headers: admin.create_new_auth_token,
            as: :json

        auditable_types = response.parsed_body['audit_logs'].pluck('auditable_type').uniq
        expect(auditable_types).to include('CoopCore::Producer')
      end

      it 'excludes Chatwoot-core audit rows' do
        producer = create(:coop_core_producer, account: account)
        producer.update!(business_name: 'Nombre Actualizado')
        team = create(:team, account: account)
        team.update!(name: 'Equipo Actualizado')

        get "/api/v1/accounts/#{account.id}/coop/audit_logs",
            headers: admin.create_new_auth_token,
            as: :json

        auditable_types = response.parsed_body['audit_logs'].pluck('auditable_type').uniq
        expect(auditable_types).not_to include('Team')
      end

      it 'does not return audit rows from another account' do
        other_account = create(:account)
        other_producer = create(:coop_core_producer, account: other_account)
        other_producer.update!(business_name: 'Otra Cooperativa')

        get "/api/v1/accounts/#{account.id}/coop/audit_logs",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response.parsed_body['audit_logs']).to be_empty
      end
    end

    context 'when the profile has audit_read' do
      it 'returns success' do
        agent = create(:user, account: account, role: :agent)
        role = create(:coop_core_staff_role, account: account, permissions: ['audit_read'])
        profile = create(:coop_core_staff_profile, account: account, user: agent)
        create(:coop_core_staff_role_assignment, account: account, staff_profile: profile, staff_role: role)

        get "/api/v1/accounts/#{account.id}/coop/audit_logs",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:success)
      end
    end
  end
end
