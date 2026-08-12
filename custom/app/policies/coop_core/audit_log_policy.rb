# audit_read (design §7.1/§9). Read-only resource (routes only expose
# :index) -- manage_permission still resolves to :audit_read (rather than
# raising NotImplementedError) purely so BasePolicy#create?/update?/
# destroy? stay safe to call even though no route can ever reach them.
class CoopCore::AuditLogPolicy < CoopCore::BasePolicy
  private

  def read_permission
    :audit_read
  end

  def manage_permission
    :audit_read
  end
end
