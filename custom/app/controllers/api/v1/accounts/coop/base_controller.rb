# Base controller for every Api::V1::Accounts::Coop::* endpoint. Reuses
# Chatwoot's existing auth/tenancy machinery (design §6.1) and adds a CoopFlow
# module gate on top of it.
class Api::V1::Accounts::Coop::BaseController < Api::V1::Accounts::BaseController
  # CoopCore::ModuleGated registers the before_action that wires the real
  # module gate (design §6.1, S3.8) -- must be included before the
  # authorize_coop_resource before_action below so the gate always runs first.
  include CoopCore::ModuleGated

  # coop_module: a coop_modules.yml key this resource is gated behind, or
  # `false` for core platform resources (e.g. branches) that are never
  # module-gated. Every subclass MUST set this explicitly -- see
  # spec/custom/invariants_spec.rb.
  class_attribute :coop_module, instance_writer: false
  class_attribute :coop_resource_class, instance_writer: false

  before_action :authorize_coop_resource

  private

  def authorize_coop_resource
    authorize(coop_record)
  end

  # Member actions (show/update/destroy) authorize against the actual
  # tenant-scoped record, not the bare resource class -- CoopCore::BasePolicy
  # #show?/#update?/#destroy? call `record.id`, which raises NoMethodError on
  # a Class. Collection actions (index/create) authorize the class itself,
  # matching design §6.1. `coop_scope.find` raises RecordNotFound for a
  # cross-tenant id, which the existing RequestExceptionHandler renders as a
  # 404 -- no extra tenancy code needed here.
  #
  # Gated on action_name (not params[:id].present?) because a stray `?id=`
  # query param on a collection request (e.g. GET .../branches?id=999) would
  # otherwise be mistaken for a member request and 404 instead of listing.
  def coop_record
    return coop_resource_class unless action_name.in?(%w[show update destroy])

    @coop_record ||= coop_scope.find(params[:id])
  end

  # Explicit bang call: `Pundit::Authorization#policy_scope` (instance method,
  # this codebase's pinned pundit 2.3.0 -- there is no instance-level
  # `policy_scope!`) is not the lenient nil-returning variant; internally it
  # already delegates to `Pundit.policy_scope!`, so this raises
  # Pundit::NotDefinedError -- not a nil scope -- if a future coop resource's
  # policy is missing its `Scope` class. Calling the bang method directly
  # keeps that intent visible in code instead of relying on an internal impl
  # detail one gem upgrade away from silently changing.
  def coop_scope
    Pundit.policy_scope!(pundit_user, coop_resource_class)
  end
end
