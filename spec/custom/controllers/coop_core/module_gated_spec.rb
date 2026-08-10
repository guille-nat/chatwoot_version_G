# frozen_string_literal: true

require 'rails_helper'

# Unit-level spec for the concern's own glue logic (design §6.1, S3.8): does
# it render the 403 + error_code shape when a module resolves disabled, and
# stay silent otherwise? Whether a module actually resolves enabled/disabled
# is CoopCore::Feature::Resolver's job, already covered exhaustively by
# spec/custom/models/coop_core/feature/resolver_spec.rb -- not duplicated
# here. No real gated Coop controller exists yet (every controller shipped
# so far sets coop_module = false), so this exercises the concern directly
# against a minimal host class rather than over real HTTP routing.
RSpec.describe CoopCore::ModuleGated do
  let(:host_class) do
    Class.new do
      # This double only exercises ensure_coop_module_enabled! directly (see
      # header comment) -- it does not need before_action to actually wire
      # up a callback chain, only to not raise when the concern registers one.
      def self.before_action(*); end

      include CoopCore::ModuleGated

      class_attribute :coop_module, instance_writer: false

      attr_accessor :rendered

      def render(payload)
        self.rendered = payload
      end
    end
  end

  let(:account) { create(:account) }
  let(:instance) { host_class.new }

  before do
    allow(instance).to receive(:coop_features).and_return(CoopCore::Feature.for(account: account))
  end

  context 'when coop_module is false (core platform resource, never gated)' do
    before { host_class.coop_module = false }

    it 'does not render anything' do
      instance.send(:ensure_coop_module_enabled!)

      expect(instance.rendered).to be_nil
    end
  end

  context 'when the module resolves enabled' do
    before { host_class.coop_module = :producers }

    it 'does not render anything' do
      instance.send(:ensure_coop_module_enabled!)

      expect(instance.rendered).to be_nil
    end
  end

  context 'when the module resolves disabled' do
    before { host_class.coop_module = :market }

    it 'renders a forbidden status' do
      instance.send(:ensure_coop_module_enabled!)

      expect(instance.rendered[:status]).to eq(:forbidden)
    end

    it 'renders the module_disabled error_code' do
      instance.send(:ensure_coop_module_enabled!)

      expect(instance.rendered[:json][:error_code]).to eq('module_disabled')
    end

    it 'renders a real translated error message for the default (English) locale' do
      instance.send(:ensure_coop_module_enabled!)

      expect(instance.rendered[:json][:error]).to eq('This module is not enabled for your cooperative.')
    end

    it 'renders which module is disabled' do
      instance.send(:ensure_coop_module_enabled!)

      expect(instance.rendered[:json][:module]).to eq(:market)
    end
  end
end
