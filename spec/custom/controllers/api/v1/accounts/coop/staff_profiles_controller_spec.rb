# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Coop Staff Profiles API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }

  describe 'GET /api/v1/accounts/{account.id}/coop/staff_profiles' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/api/v1/accounts/#{account.id}/coop/staff_profiles"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when it is an authenticated administrator' do
      let(:staff_user) { create(:user, account: account) }
      let!(:profile) { create(:coop_core_staff_profile, account: account, user: staff_user) }

      it 'returns the account staff profiles' do
        get "/api/v1/accounts/#{account.id}/coop/staff_profiles",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response.parsed_body['payload'].pluck('id')).to eq([profile.id])
      end

      it 'does not return staff profiles from other accounts' do
        other_account = create(:account)
        other_user = create(:user, account: other_account)
        create(:coop_core_staff_profile, account: other_account, user: other_user)

        get "/api/v1/accounts/#{account.id}/coop/staff_profiles",
            headers: admin.create_new_auth_token,
            as: :json

        expect(response.parsed_body['payload'].pluck('id')).not_to include(profile.id + 1)
      end
    end

    context 'when it is a regular agent with no staff profile' do
      it 'returns unauthorized' do
        agent = create(:user, account: account, role: :agent)

        get "/api/v1/accounts/#{account.id}/coop/staff_profiles",
            headers: agent.create_new_auth_token,
            as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/coop/staff_profiles/{id}' do
    let(:staff_user) { create(:user, account: account) }
    let(:profile) { create(:coop_core_staff_profile, account: account, user: staff_user) }

    it 'returns the staff profile' do
      get "/api/v1/accounts/#{account.id}/coop/staff_profiles/#{profile.id}",
          headers: admin.create_new_auth_token,
          as: :json

      expect(response.parsed_body['payload']['id']).to eq(profile.id)
    end

    it 'returns not found for a staff profile belonging to another account' do
      other_account = create(:account)
      other_user = create(:user, account: other_account)
      other_profile = create(:coop_core_staff_profile, account: other_account, user: other_user)

      get "/api/v1/accounts/#{account.id}/coop/staff_profiles/#{other_profile.id}",
          headers: admin.create_new_auth_token,
          as: :json

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/coop/staff_profiles' do
    let(:staff_user) { create(:user, account: account) }
    let(:staff_role) { create(:coop_core_staff_role, account: account) }

    it 'creates a staff profile' do
      expect do
        post "/api/v1/accounts/#{account.id}/coop/staff_profiles",
             params: { staff_profile: { user_id: staff_user.id } },
             headers: admin.create_new_auth_token,
             as: :json
      end.to change(CoopCore::StaffProfile, :count).by(1)

      expect(response).to have_http_status(:success)
    end

    it 'creates a role assignment via nested role_assignments_attributes' do
      post "/api/v1/accounts/#{account.id}/coop/staff_profiles",
           params: { staff_profile: { user_id: staff_user.id, role_assignments_attributes: [{ staff_role_id: staff_role.id }] } },
           headers: admin.create_new_auth_token,
           as: :json

      expect(response.parsed_body['payload']['role_assignments'].pluck('staff_role_id')).to eq([staff_role.id])
    end

    it 'returns unprocessable_entity for a user outside the account' do
      outsider = create(:user)

      post "/api/v1/accounts/#{account.id}/coop/staff_profiles",
           params: { staff_profile: { user_id: outsider.id } },
           headers: admin.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'PATCH /api/v1/accounts/{account.id}/coop/staff_profiles/{id}' do
    let(:staff_user) { create(:user, account: account) }
    let(:profile) { create(:coop_core_staff_profile, account: account, user: staff_user, active: true) }

    it 'updates the staff profile' do
      patch "/api/v1/accounts/#{account.id}/coop/staff_profiles/#{profile.id}",
            params: { staff_profile: { active: false } },
            headers: admin.create_new_auth_token,
            as: :json

      expect(response.parsed_body['payload']['active']).to be false
    end
  end

  describe 'DELETE /api/v1/accounts/{account.id}/coop/staff_profiles/{id}' do
    let(:staff_user) { create(:user, account: account) }

    it 'deletes the staff profile' do
      profile = create(:coop_core_staff_profile, account: account, user: staff_user)

      expect do
        delete "/api/v1/accounts/#{account.id}/coop/staff_profiles/#{profile.id}",
               headers: admin.create_new_auth_token,
               as: :json
      end.to change(CoopCore::StaffProfile, :count).by(-1)

      expect(response).to have_http_status(:ok)
    end

    it 'returns not found for a staff profile belonging to another account' do
      other_account = create(:account)
      other_user = create(:user, account: other_account)
      other_profile = create(:coop_core_staff_profile, account: other_account, user: other_user)

      expect do
        delete "/api/v1/accounts/#{account.id}/coop/staff_profiles/#{other_profile.id}",
               headers: admin.create_new_auth_token,
               as: :json
      end.not_to change(CoopCore::StaffProfile, :count)

      expect(response).to have_http_status(:not_found)
    end
  end
end
