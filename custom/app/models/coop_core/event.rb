# CoopFlow-owned event outbox (design §8.4/§8.5). A row here is the durable
# record of "this happened"; CoopCore::DeliverEventJob reads FROM this table
# (never from the Sidekiq payload alone) so a Redis loss never loses an
# event.
class CoopCore::Event < CoopCore::ApplicationRecord
  include CoopCore::AccountScoped

  validates :key, presence: true
  validates :occurred_at, presence: true
  validates :idempotency_key, presence: true
  # NOT `presence: true` -- an empty Hash (`{}`) is a legitimate payload (an
  # event that only needs its key/subject to carry meaning), but Rails
  # treats `{}.blank?` as true, so `presence: true` would wrongly reject it.
  # The DB NOT NULL constraint (migration 20260812120000) still rejects an
  # actual nil.
  validate :payload_is_not_nil

  # Enqueue only after the outbox row is actually committed (design §8.4
  # atomicity requirement): `.publish` may run inside the caller's own
  # transaction (e.g. Producer#publish_producer_created_event runs from an
  # after_create_commit, but a future caller could wrap `.publish` in an
  # explicit transaction of its own). Enqueuing straight from `.publish`
  # would risk Sidekiq picking up CoopCore::DeliverEventJob before the row is
  # visible on another connection, and the job's own `Event.find_by` would
  # 404. after_commit on: :create defers the enqueue until the row is
  # guaranteed durable, and only fires once per row -- a rescued
  # RecordNotUnique (duplicate publish, see .publish below) never creates a
  # second row, so it never re-enqueues either.
  after_commit :enqueue_deliveries, on: :create

  # Outbox publish. idempotency_key formula is fixed by design §8.4:
  # "<event_key>:<subject_global_id>:<occurred_at_epoch_seconds>". Relies on
  # the DB unique index (account_id, idempotency_key) as the actual
  # concurrency guard rather than a Rails-level uniqueness validation --
  # same "DB constraint over app-level pre-check" lesson as
  # Producer::ContactLinkable#link_contact (S4a/S4b review-fixes): a
  # duplicate publish raising ActiveRecord::RecordNotUnique is a success
  # case (someone already published this exact event), not an error.
  def self.publish(key, account:, subject:, payload:)
    occurred_at = Time.current
    idempotency_key = "#{key}:#{subject.to_global_id}:#{occurred_at.to_i}"

    create!(
      account: account,
      key: key.to_s,
      payload: payload,
      occurred_at: occurred_at,
      idempotency_key: idempotency_key
    )
  rescue ActiveRecord::RecordNotUnique
    find_by(account_id: account.id, idempotency_key: idempotency_key)
  end

  private

  def payload_is_not_nil
    errors.add(:payload, :blank) if payload.nil?
  end

  def enqueue_deliveries
    ::CoopCore::EventSubscription.active.matching(key).where(account_id: account_id).find_each do |subscription|
      ::CoopCore::DeliverEventJob.perform_later(id, subscription.id)
    end
  end
end
