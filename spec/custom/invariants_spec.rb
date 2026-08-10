# frozen_string_literal: true

require 'rails_helper'

# Cheap, high-leverage meta-specs that catch future mistakes as CoopFlow
# models land across S2-S7 (design §10.2), not just today's. Every check
# below is real (not a placeholder) -- most are vacuously true right now
# because S1 ships no migrated tenant-scoped model yet (CoopCore::Producer is
# a table-less stub until S4a). CoopCore::BasePolicy::Scope already exists,
# so the policy-scope invariant is meaningfully exercised from S1 onward.
# rubocop:disable RSpec/DescribeClass -- describes cross-cutting invariants, not one class
RSpec.describe 'CoopCore invariants' do
  # eager_load is idempotent (a no-op after the first call in this process),
  # so running it per-example is cheap and avoids before(:all) state leakage.
  before do
    Rails.autoloaders.main.eager_load
  end

  def migrated_coop_core_models
    CoopCore::ApplicationRecord.descendants.select(&:table_exists?)
  end

  def coop_core_policy_scope_classes
    ([CoopCore::BasePolicy] + CoopCore::BasePolicy.descendants).filter_map do |policy_class|
      policy_class.const_get(:Scope, false) if policy_class.const_defined?(:Scope, false)
    end
  end

  it 'gives every tenant-scoped CoopCore model a non-nullable account_id column' do
    offenders = migrated_coop_core_models.reject do |model|
      next true if model.name == 'CoopCore::ModuleDefault'

      column = model.columns_hash['account_id']
      column.present? && !column.null
    end

    expect(offenders).to be_empty
  end

  it 'includes CoopCore::AccountScoped on every tenant-scoped CoopCore model' do
    offenders = migrated_coop_core_models.reject do |model|
      next true if model.name == 'CoopCore::ModuleDefault'

      model.include?(CoopCore::AccountScoped)
    end

    expect(offenders).to be_empty
  end

  it 'audits every tenant-scoped CoopCore model' do
    offenders = migrated_coop_core_models.reject do |model|
      next true if model.name == 'CoopCore::ModuleDefault'

      model.respond_to?(:auditing_enabled) && model.auditing_enabled
    end

    expect(offenders).to be_empty
  end

  it 'raises CoopCore::MissingAccountContext from every CoopCore policy Scope without an account' do
    offenders = coop_core_policy_scope_classes.reject do |scope_class|
      scope_class.new({ user: nil, account: nil, account_user: nil }, CoopCore::Producer).resolve
      false
    rescue CoopCore::MissingAccountContext
      true
    end

    expect(offenders).to be_empty
  end

  it 'keeps ModuleSetting/ModuleDefault references inside coop_core/feature/' do
    offending_files = Dir[Rails.root.join('custom/app/**/*.rb')].select do |path|
      next false if path.include?('/coop_core/feature/')

      File.read(path).match?(/\bModuleSetting\b|\bModuleDefault\b/)
    end

    expect(offending_files).to be_empty
  end
end
# rubocop:enable RSpec/DescribeClass
