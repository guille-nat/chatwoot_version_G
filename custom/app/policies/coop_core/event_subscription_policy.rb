# Event subscriptions are a platform integration concern (webhook endpoints
# + shared secrets for the whole cooperative), not a per-resource CRUD
# surface -- the S6 permission vocabulary has no events_* key, so this gates
# on modules_manage (design §7.1's closest existing "platform integration
# configuration" permission) for BOTH read and manage, not just create/
# update/destroy. Documented choice (S7 task doc): reading the subscription
# list is itself sensitive (URLs, active state) even though the secret
# column is write-only in every response.
class CoopCore::EventSubscriptionPolicy < CoopCore::BasePolicy
  private

  def read_permission
    :modules_manage
  end

  def manage_permission
    :modules_manage
  end
end
