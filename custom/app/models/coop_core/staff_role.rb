# A cooperative's staff role (rol de staff) -- design §4/§7. Grants a set of
# CoopCore::Permission::ALL permissions to whichever CoopCore::StaffProfile
# rows are assigned it, via CoopCore::StaffRoleAssignment.
#
# Seeded per account (es-AR, design §7.2) with system: true -- undeletable,
# but permissions stay editable so a cooperative can adjust a seeded role's
# scope without losing the ability to identify it as a starting point.
class CoopCore::StaffRole < CoopCore::ApplicationRecord
  include CoopCore::AccountScoped

  has_many :role_assignments, class_name: 'CoopCore::StaffRoleAssignment', dependent: :destroy,
                              inverse_of: :staff_role

  # "all reads" = the seven *_read permissions only -- audit_read is listed
  # separately for gerente/administracion, so it is NOT part of this shared
  # base (design §7.2 clarification).
  ALL_READS = %w[
    producers_read fields_read plots_read crops_read branches_read staff_read modules_read
  ].freeze

  SEEDS = {
    'gerente' => {
      name: 'Gerente',
      permissions: ALL_READS + %w[producers_manage branches_manage staff_manage modules_manage audit_read export_data]
    },
    'administracion' => {
      name: 'Administración',
      permissions: ALL_READS + %w[producers_manage audit_read export_data]
    },
    'comercial' => {
      name: 'Comercial',
      permissions: ALL_READS + %w[producers_manage]
    },
    'agronomo' => {
      name: 'Agrónomo',
      permissions: ALL_READS + %w[fields_manage plots_manage crops_manage]
    },
    'logistica' => {
      name: 'Logística',
      permissions: ALL_READS
    },
    'operador' => {
      name: 'Operador',
      permissions: ALL_READS
    }
  }.freeze

  validates :key, presence: true, uniqueness: { scope: :account_id }
  validates :name, presence: true
  validates :permissions, inclusion: { in: ::CoopCore::Permission::ALL }

  before_validation :prepare_permissions
  before_destroy :reject_system_role_deletion

  # Idempotent: only fills in the seeded roles missing for this account, and
  # never touches an existing row's permissions -- a cooperative that already
  # edited a seeded role keeps its edits across re-seeding (e.g. a later
  # slice appending new permission keys to SEEDS).
  def self.ensure_seeded!(account)
    SEEDS.each do |key, attrs|
      find_or_create_by!(account_id: account.id, key: key) do |role|
        role.name = attrs[:name]
        role.permissions = attrs[:permissions]
        role.system = true
      end
    end
  end

  private

  def prepare_permissions
    self.permissions = Array(permissions).compact.uniq
  end

  # `system` roles are undeletable via a direct StaffRole#destroy call (the
  # API's DELETE /coop/staff_roles/:id) but must NOT block a whole-account
  # destroy: `destroyed_by_association` is set by Rails when this record is
  # being removed as part of Custom::Concerns::Account's `dependent: :destroy`
  # cascade (Account#destroy!) -- without this guard, any account with a
  # seeded system role would raise ActiveRecord::RecordNotDestroyed and become
  # permanently undestroyable the moment ensure_seeded! ever ran for it
  # (verified empirically against activerecord 7.1.5.2).
  def reject_system_role_deletion
    return if destroyed_by_association.present?
    return unless system?

    errors.add(:base, 'no se puede eliminar un rol del sistema')
    throw :abort
  end
end
