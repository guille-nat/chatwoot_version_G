# frozen_string_literal: true

require 'rails_helper'

# CoopFlow-owned outbox (design §8.4/§8.5). CoopCore::Event.publish inserts
# the outbox row and defers delivery enqueue to an after_commit callback (see
# class comment) -- ActiveJob::TestHelper's :test adapter still runs
# after_commit callbacks synchronously within the (non-real) test-transaction
# wrapper, so `have_enqueued_job` works the same as it would against a real
# committed transaction.
RSpec.describe CoopCore::Event, type: :model do
  include ActiveJob::TestHelper

  let(:account) { create(:account) }
  let(:contact) { create(:contact, account: account) }

  describe '.publish' do
    it 'creates an outbox row' do
      expect do
        described_class.publish(:producer_created, account: account, subject: contact, payload: { foo: 'bar' })
      end.to change(described_class, :count).by(1)
    end

    it 'stores the given payload' do
      event = described_class.publish(:producer_created, account: account, subject: contact, payload: { foo: 'bar' })

      expect(event.payload).to eq('foo' => 'bar')
    end

    it 'stores the key as a string' do
      event = described_class.publish(:producer_created, account: account, subject: contact, payload: {})

      expect(event.key).to eq('producer_created')
    end

    it 'builds the idempotency key from the event key, subject gid and occurred_at epoch' do
      travel_to Time.zone.local(2026, 8, 12, 10, 0, 0) do
        event = described_class.publish(:producer_created, account: account, subject: contact, payload: {})

        expect(event.idempotency_key).to eq("producer_created:#{contact.to_global_id}:#{Time.current.to_i}")
      end
    end

    it 'does not raise when the exact same event is published twice in the same second' do
      travel_to Time.zone.local(2026, 8, 12, 10, 0, 0) do
        described_class.publish(:producer_created, account: account, subject: contact, payload: {})

        expect do
          described_class.publish(:producer_created, account: account, subject: contact, payload: {})
        end.not_to raise_error
      end
    end

    it 'collapses a duplicate publish onto the original row' do
      travel_to Time.zone.local(2026, 8, 12, 10, 0, 0) do
        first_event = described_class.publish(:producer_created, account: account, subject: contact, payload: {})

        expect do
          described_class.publish(:producer_created, account: account, subject: contact, payload: {})
        end.not_to change(described_class, :count)

        expect(described_class.last.id).to eq(first_event.id)
      end
    end

    context 'when there is a matching active subscription' do
      let!(:subscription) { create(:coop_core_event_subscription, account: account) }

      it 'enqueues a delivery job for the subscription' do
        event = described_class.publish(:producer_created, account: account, subject: contact, payload: {})

        expect(CoopCore::DeliverEventJob).to have_been_enqueued.with(event.id, subscription.id)
      end
    end

    context 'when the subscription is inactive' do
      let!(:subscription) { create(:coop_core_event_subscription, account: account, active: false) }

      it 'does not enqueue a delivery job' do
        described_class.publish(:producer_created, account: account, subject: contact, payload: {})

        expect(CoopCore::DeliverEventJob).not_to have_been_enqueued.with(anything, subscription.id)
      end
    end

    context 'when the subscription only listens to a different event key' do
      let!(:subscription) { create(:coop_core_event_subscription, account: account, event_keys: ['link_conflict']) }

      it 'does not enqueue a delivery job' do
        described_class.publish(:producer_created, account: account, subject: contact, payload: {})

        expect(CoopCore::DeliverEventJob).not_to have_been_enqueued.with(anything, subscription.id)
      end
    end

    context 'when the subscription belongs to a different account' do
      let!(:other_account) { create(:account) }
      let!(:subscription) { create(:coop_core_event_subscription, account: other_account) }

      it 'does not enqueue a delivery job' do
        described_class.publish(:producer_created, account: account, subject: contact, payload: {})

        expect(CoopCore::DeliverEventJob).not_to have_been_enqueued.with(anything, subscription.id)
      end
    end

    context 'when called inside a caller-owned transaction' do
      let!(:subscription) { create(:coop_core_event_subscription, account: account) }

      # Regression for the transaction-poisoning bug: a duplicate publish's
      # RecordNotUnique must only unwind a SAVEPOINT (transaction(requires_new:
      # true)), never the caller's enclosing transaction. Before the fix, the
      # second publish's rescue-side `find_by` raised
      # PG::InFailedSqlTransaction because the whole outer transaction was
      # already aborted, and that raise rolled back the unrelated
      # `account.update!` performed in the same transaction below.
      it 'does not poison the enclosing transaction on a duplicate publish' do
        travel_to Time.zone.local(2026, 8, 12, 10, 0, 0) do
          expect do
            ActiveRecord::Base.transaction do
              described_class.publish(:producer_created, account: account, subject: contact, payload: {})
              described_class.publish(:producer_created, account: account, subject: contact, payload: {})
              account.update!(name: 'Poison Probe Cooperative')
            end
          end.not_to raise_error

          expect(described_class.count).to eq(1)
          expect(account.reload.name).to eq('Poison Probe Cooperative')
          expect(CoopCore::DeliverEventJob).to have_been_enqueued.with(described_class.last.id, subscription.id).once
        end
      end

      it 'enqueues nothing when the caller transaction is rolled back after a successful publish' do
        expect do
          ActiveRecord::Base.transaction do
            described_class.publish(:producer_created, account: account, subject: contact, payload: {})
            raise ActiveRecord::Rollback
          end
        end.not_to raise_error

        expect(described_class.count).to eq(0)
        expect(CoopCore::DeliverEventJob).not_to have_been_enqueued
      end
    end
  end

  describe 'auditing' do
    it 'is audited' do
      expect(described_class.auditing_enabled).to be true
    end
  end
end
