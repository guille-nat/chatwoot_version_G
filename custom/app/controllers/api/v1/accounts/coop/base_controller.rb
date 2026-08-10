# Base controller for every Api::V1::Accounts::Coop::* endpoint. Reuses
# Chatwoot's existing auth/tenancy machinery (design §6.1) and adds a CoopFlow
# module gate on top of it.
class Api::V1::Accounts::Coop::BaseController < Api::V1::Accounts::BaseController
  # coop_module: a coop_modules.yml key this resource is gated behind, or
  # `false` for core platform resources (e.g. branches) that are never
  # module-gated. Every subclass MUST set this explicitly -- see
  # spec/custom/invariants_spec.rb.
  class_attribute :coop_module, instance_writer: false
  class_attribute :coop_resource_class, instance_writer: false

  before_action :ensure_coop_module_enabled!
  before_action :authorize_coop_resource

  private

  # S1 stub: CoopCore::Feature (the module registry/resolver) lands in S3.
  # S3.8 replaces this with the real 403 + error_code: 'module_disabled' check.
  def ensure_coop_module_enabled!
    true
  end

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
  def coop_record
    return coop_resource_class if params[:id].blank?

    @coop_record ||= coop_scope.find(params[:id])
  end

  def coop_scope
    policy_scope(coop_resource_class)
  end
end
