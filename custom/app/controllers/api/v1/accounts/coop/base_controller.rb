# Base controller for every Api::V1::Accounts::Coop::* endpoint. Reuses
# Chatwoot's existing auth/tenancy machinery (design §6.1) and adds a CoopFlow
# module gate on top of it.
class Api::V1::Accounts::Coop::BaseController < Api::V1::Accounts::BaseController
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
    authorize(coop_resource_class)
  end

  def coop_scope
    policy_scope(coop_resource_class)
  end
end
