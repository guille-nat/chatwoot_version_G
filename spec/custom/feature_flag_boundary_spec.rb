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

  it 'keeps ModuleSetting/ModuleDefault references inside coop_core/feature/ or their own model file' do
    offending_files = Dir[Rails.root.join('custom/{app,lib}/**/*.rb')].select do |path|
      next false if path.include?('/coop_core/feature/')
      next false if path.end_with?('/coop_core/feature.rb') # the Feature namespace file itself
      next false if File.basename(path).in?(%w[module_setting.rb module_default.rb])

      File.read(path).match?(/\bModuleSetting\b|\bModuleDefault\b/)
    end

    expect(offending_files).to be_empty
  end
end
# rubocop:enable RSpec/DescribeClass
