# A cooperative's branch/sucursal (design §4). Org node used as the branch
# scope for feature flags (S3) and staff role assignments (S6).
class CoopCore::Branch < CoopCore::ApplicationRecord
  include CoopCore::AccountScoped

  # Deleting a branch must unassign its producers, never block or
  # cascade-delete them (design decision, S4a review). dependent: :nullify
  # unassigns via a bulk UPDATE, not per-record saves -- it will NOT go
  # through Producer callbacks or leave an `audited` trail for the
  # unassignment. The DB-level FK (migration 20260811090000) carries
  # on_delete: :nullify as the backstop so no path (this association,
  # console, raw SQL) can ever block or bypass the unassignment.
  has_many :producers, class_name: 'CoopCore::Producer', dependent: :nullify
  # Same rationale as #producers above: deleting a branch must unassign its
  # fields, never block or cascade-delete them. coop_core_fields.branch_id
  # carries the matching on_delete: :nullify DB backstop.
  has_many :fields, class_name: 'CoopCore::Field', dependent: :nullify
  # Review-fix (S6): the OPPOSITE rule of #producers/#fields above. A branch-
  # scoped CoopCore::StaffRoleAssignment's branch_id being set to NULL is NOT
  # a safe fallback here -- NULL already means "cooperative-wide by design"
  # (CoopCore::BasePolicy::Scope#accessible_branch_ids), so nullifying it on
  # branch deletion would silently WIDEN the profile's access from one branch
  # to the whole cooperative. The assignment must be destroyed instead.
  # dependent: :destroy (never :destroy_async) so this runs synchronously,
  # inside the same transaction as the branch delete -- see
  # db/migrate/20260812110200_create_coop_core_staff_role_assignments.rb,
  # which carries the matching on_delete: :cascade DB backstop.
  has_many :staff_role_assignments, class_name: 'CoopCore::StaffRoleAssignment', dependent: :destroy

  KINDS = %w[branch plant silo office].freeze

  validates :name, presence: true
  validates :kind, presence: true, inclusion: { in: KINDS }
  validates :timezone, presence: true
  validates :code, uniqueness: { scope: :account_id, case_sensitive: false }, allow_nil: true

  before_validation :prepare_jsonb_attributes

  scope :active, -> { where(active: true) }

  private

  def prepare_jsonb_attributes
    self.settings = {} unless settings.is_a?(Hash)
  end
end
