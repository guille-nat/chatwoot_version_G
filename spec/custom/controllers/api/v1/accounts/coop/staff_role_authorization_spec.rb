# frozen_string_literal: true

require 'rails_helper'

# THE design-mandated regression (design §7, slice table row S6): a staff
# role's permission scope must be enforced over real HTTP, not just at the
# policy unit level -- an agronomo can manage fields (their domain) but not
# producers (commercial data), even though both endpoints share the same
# `producers` coop_modules.yml gate.
RSpec.describe 'Coop staff role permission enforcement', type: :request do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:agronomo_role) do
    create(:coop_core_staff_role, account: account, key: 'agronomo',
                                  permissions: %w[fields_read fields_manage plots_manage crops_manage producers_read])
  end
  let!(:profile) { create(:coop_core_staff_profile, account: account, user: agent) }

  before { create(:coop_core_staff_role_assignment, account: account, staff_profile: profile, staff_role: agronomo_role) }

  describe 'POST /api/v1/accounts/{account.id}/coop/producers' do
    it 'is denied for an agronomo' do
      post "/api/v1/accounts/#{account.id}/coop/producers",
           params: { producer: { business_name: 'Productor Nuevo' } },
           headers: agent.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it 'does not create the producer' do
      expect do
        post "/api/v1/accounts/#{account.id}/coop/producers",
             params: { producer: { business_name: 'Productor Nuevo' } },
             headers: agent.create_new_auth_token,
             as: :json
      end.not_to change(CoopCore::Producer, :count)
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/coop/producers/{producer.id}/fields' do
    let(:producer) { create(:coop_core_producer, account: account) }

    it 'is permitted for an agronomo' do
      post "/api/v1/accounts/#{account.id}/coop/producers/#{producer.id}/fields",
           params: { field: { name: 'Campo Norte' } },
           headers: agent.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:success)
    end

    it 'creates the field' do
      expect do
        post "/api/v1/accounts/#{account.id}/coop/producers/#{producer.id}/fields",
             params: { field: { name: 'Campo Norte' } },
             headers: agent.create_new_auth_token,
             as: :json
      end.to change(CoopCore::Field, :count).by(1)
    end
  end
end
