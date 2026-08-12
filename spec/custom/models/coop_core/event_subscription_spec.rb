# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CoopCore::EventSubscription, type: :model do
  let(:account) { create(:account) }

  describe 'validations' do
    it 'is invalid without a url' do
      subscription = build(:coop_core_event_subscription, account: account, url: nil)

      expect(subscription).not_to be_valid
    end

    it 'is invalid with a non-http(s) url' do
      subscription = build(:coop_core_event_subscription, account: account, url: 'ftp://example.com')

      expect(subscription).not_to be_valid
    end

    it 'is valid with an https url' do
      subscription = build(:coop_core_event_subscription, account: account, url: 'https://example.com/hook')

      expect(subscription).to be_valid
    end
  end

  describe 'secret' do
    it 'auto-generates a secret when none is given' do
      subscription = create(:coop_core_event_subscription, account: account)

      expect(subscription.secret).to be_present
    end

    it 'keeps a caller-supplied secret' do
      subscription = create(:coop_core_event_subscription, account: account, secret: 'shared-secret-123')

      expect(subscription.secret).to eq('shared-secret-123')
    end
  end

  describe 'event_keys normalization' do
    it 'strips blank entries' do
      subscription = create(:coop_core_event_subscription, account: account, event_keys: ['producer_created', '', ' '])

      expect(subscription.event_keys).to eq(['producer_created'])
    end

    it 'defaults to an empty array' do
      subscription = create(:coop_core_event_subscription, account: account)

      expect(subscription.event_keys).to eq([])
    end
  end

  describe 'defaults' do
    it 'defaults active to true' do
      subscription = described_class.new

      expect(subscription.active).to be true
    end
  end

  describe '.active' do
    it 'includes only active subscriptions' do
      active = create(:coop_core_event_subscription, account: account, active: true)
      create(:coop_core_event_subscription, account: account, active: false)

      expect(described_class.active).to contain_exactly(active)
    end
  end

  describe '.matching' do
    it 'includes a subscription with an empty event_keys list for any key' do
      subscription = create(:coop_core_event_subscription, account: account, event_keys: [])

      expect(described_class.matching('producer_created')).to include(subscription)
    end

    it 'includes a subscription whose event_keys contains the key' do
      subscription = create(:coop_core_event_subscription, account: account, event_keys: ['producer_created'])

      expect(described_class.matching('producer_created')).to include(subscription)
    end

    it 'excludes a subscription whose event_keys does not contain the key' do
      subscription = create(:coop_core_event_subscription, account: account, event_keys: ['link_conflict'])

      expect(described_class.matching('producer_created')).not_to include(subscription)
    end
  end

  describe 'auditing' do
    it 'is audited' do
      expect(described_class.auditing_enabled).to be true
    end

    it 'does not include the secret in audited_changes' do
      subscription = create(:coop_core_event_subscription, account: account)

      expect(subscription.audits.last.audited_changes).not_to have_key('secret')
    end
  end

  describe 'Account association' do
    it 'is included in the owning account coop_event_subscriptions association' do
      subscription = create(:coop_core_event_subscription, account: account)

      expect(account.coop_event_subscriptions).to include(subscription)
    end
  end
end
