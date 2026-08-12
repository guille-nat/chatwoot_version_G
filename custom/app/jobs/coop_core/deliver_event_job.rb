# Delivers one outbox row to one subscription (design §8.5). Mirrors the
# core WebhookJob/Webhooks::Trigger HTTP pattern (SafeFetch, POST JSON,
# app/jobs/webhook_job.rb + lib/webhooks/trigger.rb) rather than reinventing
# request plumbing. Reads both the event and the subscription fresh from the
# DB by id (never passed as objects, rails-background-jobs convention) --
# this is also *why* delivery can never lose an event even if Redis does:
# the row this job re-reads is the durable source of truth, not its own
# arguments.
class CoopCore::DeliverEventJob < ApplicationJob
  queue_as :medium

  # Raised for anything SafeFetch itself deems transient/retryable (timeouts,
  # any non-2xx HTTP status -- SafeFetch::HttpError covers both 4xx and 5xx).
  # A dedicated class (rather than rescuing SafeFetch::Error directly in
  # retry_on) keeps the retry contract scoped to delivery failures only, not
  # to every SafeFetch error type -- see the discard_on branch below for the
  # ones that must NOT retry.
  class DeliveryError < StandardError; end

  # 5 attempts, polynomial backoff -- same idiom as
  # MutexApplicationJob.retry_on_lock_conflict and the other retry_on call
  # sites in this codebase (app/jobs/hook_job.rb,
  # app/jobs/send_on_slack_job.rb). After the 5th attempt the block runs
  # instead of re-raising (ActiveJob::Exceptions#retry_on semantics): the
  # job completes without raising into Sidekiq, logs, and reports to the
  # exception tracker. F1 ships no dead-letter/redelivery UI -- a
  # permanently failing subscription is visible only via these logs/Sentry
  # until a later slice adds one.
  retry_on DeliveryError, wait: :polynomially_longer, attempts: 5 do |job, error|
    Rails.logger.error(
      "[CoopCore] event delivery exhausted retries event_id=#{job.arguments[0]} " \
      "subscription_id=#{job.arguments[1]}: #{error.message}"
    )
    ChatwootExceptionTracker.new(error).capture_exception
  end

  # A bad or SSRF-blocked subscription URL is a permanent failure -- no
  # number of retries fixes it. Discarding (not retrying) it also means a
  # misconfigured subscription can never itself blow up Sidekiq retry
  # volume.
  discard_on SafeFetch::InvalidUrlError, SafeFetch::UnsafeUrlError do |job, error|
    Rails.logger.warn(
      "[CoopCore] event delivery discarded (invalid subscription url) event_id=#{job.arguments[0]} " \
      "subscription_id=#{job.arguments[1]}: #{error.message}"
    )
  end

  def perform(event_id, subscription_id)
    event = ::CoopCore::Event.find_by(id: event_id)
    subscription = ::CoopCore::EventSubscription.active.find_by(id: subscription_id)
    return if event.blank? || subscription.blank?

    deliver(event, subscription)
  end

  private

  def deliver(event, subscription)
    body = payload_for(event).to_json

    SafeFetch.fetch(
      subscription.url,
      method: :post,
      body: body,
      headers: request_headers(body, subscription.secret),
      open_timeout: 5,
      read_timeout: 5,
      validate_content_type: false
    ) { |_response| nil }
  rescue SafeFetch::InvalidUrlError, SafeFetch::UnsafeUrlError
    raise
  rescue SafeFetch::Error => e
    raise DeliveryError, e.message
  end

  def payload_for(event)
    { event: event.key, occurred_at: event.occurred_at.iso8601, payload: event.payload }
  end

  # HMAC-SHA256 of the raw JSON body, hex-encoded, in X-CoopFlow-Signature
  # (S7 task doc). Deliberately over the raw body only (no timestamp prefix)
  # -- unlike Chatwoot's own X-Chatwoot-Signature convention
  # (lib/webhooks/trigger.rb) -- to keep verification a single
  # HMAC(body, secret) call for external ERP integrations, matching the
  # explicit wording of the S7 spec.
  def request_headers(body, secret)
    {
      'Content-Type' => 'application/json',
      'X-CoopFlow-Signature' => OpenSSL::HMAC.hexdigest('SHA256', secret, body)
    }
  end
end
