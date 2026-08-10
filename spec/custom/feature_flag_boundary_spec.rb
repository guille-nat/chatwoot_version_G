# frozen_string_literal: true

require 'rails_helper'

# R3 (design §5.5, §14): guards against a second, competing feature-flag
# system taking root. Two independent lints, relocated here from
# coop_core_wiring_spec.rb and invariants_spec.rb once CoopCore::Feature
# landed (S3) so both boundary checks live in one dedicated file.
# rubocop:disable RSpec/DescribeClass -- describes a cross-cutting boundary, not one class
RSpec.describe 'CoopFlow feature-flag boundary' do
  it 'does not declare any coop-prefixed key in config/features.yml' do
    feature_names = YAML.load_file(Rails.root.join('config/features.yml')).map { |feature| feature['name'] }

    expect(feature_names.grep(/\A(coop|coopflow)/)).to be_empty
  end

  it 'keeps ModuleSetting/ModuleDefault references inside coop_core/feature/, their own model file, or sanctioned wiring' do
    # Sanctioned exceptions, beyond the resolution machinery itself: files
    # that only need to *name* CoopCore::ModuleSetting for Rails/Pundit
    # wiring (association class_name:, Pundit policy resolution via
    # coop_resource_class) rather than to read or write flag state directly.
    # All actual reads/writes go through CoopCore::Feature -- see
    # ModulesController#update (CoopCore::Feature.set_account_override) and
    # CoopCore::Feature::Resolver (reads).
    wiring_only_files = %w[
      custom/app/controllers/api/v1/accounts/coop/modules_controller.rb
      custom/app/models/custom/concerns/account.rb
    ]

    offending_files = Dir[Rails.root.join('custom/{app,lib}/**/*.rb')].select do |path|
      next false if path.include?('/coop_core/feature/')
      next false if path.end_with?('/coop_core/feature.rb') # the Feature namespace file itself
      next false if File.basename(path).in?(%w[module_setting.rb module_default.rb])
      next false if wiring_only_files.any? { |wiring_path| path.end_with?(wiring_path) }

      File.read(path).match?(/\bModuleSetting\b|\bModuleDefault\b/)
    end

    expect(offending_files).to be_empty
  end
end
# rubocop:enable RSpec/DescribeClass
