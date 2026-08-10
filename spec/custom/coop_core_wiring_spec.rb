# frozen_string_literal: true

require 'rails_helper'

# Proves the custom/ overlay boots, autoloads, and injects correctly using the
# same mechanism enterprise/ already relies on. See custom/README.md.
# rubocop:disable RSpec/DescribeClass -- describes overlay boot behavior, not one class
RSpec.describe 'CoopCore wiring' do
  it 'marks the app as running the custom/ overlay' do
    expect(ChatwootApp.custom?).to be true
  end

  it 'includes both enterprise and custom in ChatwootApp.extensions' do
    expect(ChatwootApp.extensions).to eq(%w[enterprise custom])
  end

  it 'keeps enterprise in ChatwootApp.extensions even when DISABLE_ENTERPRISE is set (ADR-009)' do
    with_modified_env DISABLE_ENTERPRISE: 'true' do
      expect(ChatwootApp.extensions).to include('enterprise')
    end
  end

  it 'eager-loads CoopCore code without raising' do
    expect { Rails.autoloaders.main.eager_load }.not_to raise_error
  end

  it 'prepends Custom::AsyncDispatcher onto AsyncDispatcher' do
    expect(AsyncDispatcher.ancestors).to include(Custom::AsyncDispatcher)
  end

  it 'gives Custom::AsyncDispatcher precedence over Enterprise::AsyncDispatcher' do
    ancestors = AsyncDispatcher.ancestors

    expect(ancestors.index(Custom::AsyncDispatcher)).to be < ancestors.index(Enterprise::AsyncDispatcher)
  end

  it 'registers CoopCoreListener as an async listener' do
    expect(AsyncDispatcher.new.listeners).to include(CoopCoreListener.instance)
  end

  it 'routes the coop producers index endpoint' do
    # NOTE: Rails' recognize_path resolves req.controller_class as part of
    # matching, so it raises on any route whose controller isn't implemented
    # yet -- true for every S1 route (controllers arrive incrementally in
    # S2-S7). Inspecting route.defaults proves the route tree is wired
    # without requiring the controllers to exist.
    route = Rails.application.routes.routes.find do |candidate|
      candidate.verb == 'GET' && candidate.path.spec.to_s == '/api/v1/accounts/:account_id/coop/producers(.:format)'
    end

    expect(route.defaults).to include(controller: 'api/v1/accounts/coop/producers', action: 'index')
  end

  it 'gives custom/app/views precedence over enterprise/app/views' do
    paths = ActionController::Base.view_paths.map(&:to_s)
    custom_index = paths.index { |path| path.end_with?('custom/app/views') }
    enterprise_index = paths.index { |path| path.end_with?('enterprise/app/views') }

    expect(custom_index).to be < enterprise_index
  end

  it 'prefixes CoopCore table names with coop_core_' do
    expect(CoopCore::Producer.table_name).to eq('coop_core_producers')
  end

  it 'auto-includes Custom::Concerns::Account into Account' do
    expect(Account.new.respond_to?(:coop_producers)).to be true
  end
end
# rubocop:enable RSpec/DescribeClass
