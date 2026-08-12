# frozen_string_literal: true

require 'rails_helper'

# CoopFlow-owned permission vocabulary (design §7.1). Same shape as
# CustomRole::PERMISSIONS but never shares the constant -- CustomRole governs
# Chatwoot inbox/conversation/contact permissions, CoopCore::Permission
# governs CoopCore::* resources only (R4, dual role systems are accepted and
# strictly non-overlapping).
RSpec.describe CoopCore::Permission do
  describe '::ALL' do
    it 'is frozen' do
      expect(described_class::ALL).to be_frozen
    end

    it 'includes every *_read/*_manage pair from design §7.1' do
      expect(described_class::ALL).to match_array(
        %w[
          producers_read producers_manage
          fields_read fields_manage
          plots_read plots_manage
          crops_read crops_manage
          branches_read branches_manage
          staff_read staff_manage
          modules_read modules_manage
          audit_read
          export_data
        ]
      )
    end
  end
end
