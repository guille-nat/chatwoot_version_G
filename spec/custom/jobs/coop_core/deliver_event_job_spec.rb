# frozen_string_literal: true

require 'rails_helper'

# HMAC-signed webhook delivery for one outbox row -> one subscription
# (design §8.5). Mirrors Webhooks::Trigger's own spec convention (external
# boundary mocked at the class method, spec/lib/webhooks/trigger_spec.rb) --
# never hits the real network.
RSpec.describe CoopCore::DeliverEventJob, type: :job do
  include ActiveJob::TestHelper

  before { ActiveJob::Base.queue_adapter = :test }

  after do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  let(:account) { create(:account) }
  let(:contact) { create(:contact, account: account) }
  let(:event) do
    CoopCore::Event.create!(
      account: account,
      key: 'producer_created',
      payload: { producer_id: 1 },
      occurred_at: Time.current,
      idempotency_key: "producer_created:#{contact.to_global_id}:#{Time.current.to_i}"
    )
  end
  let(:subscription) { create(:coop_core_event_subscription, account: account, secret: 'shared-secret') }

  describe '#perform' do
    it 'posts the event payload as JSON to the subscription url' do
      expect(SafeFetch).to receive(:fetch).with(
        subscription.url,
        hash_including(method: :post, validate_content_type: false)
      ).and_yield(instance_double(SafeFetch::Result))

      described_class.perform_now(event.id, subscription.id)
    end

    it 'signs the body with HMAC-SHA256 of the subscription secret' do
      expected_body = { event: 'producer_created', occurred_at: event.occurred_at.iso8601, payload: { 'producer_id' => 1 } }.to_json
      expected_signature = OpenSSL::HMAC.hexdigest('SHA256', 'shared-secret', expected_body)

      expect(SafeFetch).to receive(:fetch) do |_url, **options|
        expect(options[:headers]['X-CoopFlow-Signature']).to eq(expected_signature)
      end.and_yield(instance_double(SafeFetch::Result))

      described_class.perform_now(event.id, subscription.id)
    end

    it 'does nothing when the event no longer exists' do
      expect(SafeFetch).not_to receive(:fetch)

      described_class.perform_now(-1, subscription.id)
    end

    it 'does nothing when the subscription is inactive' do
      subscription.update!(active: false)

      expect(SafeFetch).not_to receive(:fetch)

      described_class.perform_now(event.id, subscription.id)
    end

    context 'when the endpoint returns a server error' do
      before do
        allow(SafeFetch).to receive(:fetch).and_raise(SafeFetch::HttpError.new('500 Internal Server Error'))
      end

      # retry_on registers a rescue_from handler (ActiveJob::Exceptions),
      # which intercepts DeliveryError and calls retry_job instead of
      # letting it bubble up -- perform_now genuinely does not raise here,
      # it re-enqueues. See the next two examples for the actual retry
      # behavior.
      it 'does not raise' do
        expect { described_class.perform_now(event.id, subscription.id) }.not_to raise_error
      end

      it 'enqueues a retry' do
        expect { described_class.perform_now(event.id, subscription.id) }.to have_enqueued_job(described_class)
      end
    end

    context 'when the subscription url is unsafe (SSRF-blocked)' do
      before do
        allow(SafeFetch).to receive(:fetch).and_raise(SafeFetch::UnsafeUrlError.new('blocked'))
      end

      it 'does not raise' do
        expect { described_class.perform_now(event.id, subscription.id) }.not_to raise_error
      end
    end
  end

  describe 'retry configuration' do
    it 'registers a retry handler for DeliveryError' do
      handled = described_class.rescue_handlers.map(&:first)

      expect(handled).to include('CoopCore::DeliverEventJob::DeliveryError')
    end
  end
end
