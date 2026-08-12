# CRUD for a cooperative's outbound event subscriptions (webhook endpoints,
# design §8.5). Platform integration concern, not a licensable module --
# coop_module stays false, same as branches/staff_roles/modules.
#
# `secret` is intentionally permitted in create/update params (S7 task doc)
# -- CoopCore::EventSubscription#secret auto-generates via has_secure_token
# when omitted, but some receiving endpoints require a caller-chosen shared
# secret. It is never rendered back (see
# custom/app/views/api/v1/coop/models/_event_subscription.json.jbuilder) --
# write-only, same convention as any credential field in this codebase.
class Api::V1::Accounts::Coop::EventSubscriptionsController < Api::V1::Accounts::Coop::BaseController
  self.coop_module = false
  self.coop_resource_class = ::CoopCore::EventSubscription

  before_action :set_event_subscription, only: [:show, :update, :destroy]

  def index
    @event_subscriptions = coop_scope.order(:created_at)
  end

  def show; end

  def create
    @event_subscription = Current.account.coop_event_subscriptions.create!(event_subscription_params)
  end

  def update
    @event_subscription.update!(event_subscription_params)
  end

  def destroy
    @event_subscription.destroy!
    head :ok
  end

  private

  def set_event_subscription
    @event_subscription = coop_record
  end

  def event_subscription_params
    params.require(:event_subscription).permit(:url, :secret, :active, event_keys: [])
  end
end
