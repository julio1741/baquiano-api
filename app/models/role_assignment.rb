class RoleAssignment < ApplicationRecord
  belongs_to :user
  belongs_to :role
  belongs_to :assigned_by_user, class_name: "User"
  belongs_to :revoked_by_user, class_name: "User", optional: true

  validates :starts_at, presence: true

  validate :scope_matches_role

  def revoked?
    revoked_at.present?
  end

  def expired?
    expires_at.present? && expires_at <= Time.current
  end

  def active?
    !revoked? && !expired? && starts_at <= Time.current
  end

  def revoke!(by:, reason: nil)
    update!(revoked_at: Time.current, revoked_by_user: by, revocation_reason: reason)
  end

  private

  def scope_matches_role
    return unless role

    case role.scope_type
    when "platform"
      errors.add(:organization_id, "must be blank for a platform-scoped role") if organization_id.present?
      errors.add(:branch_id, "must be blank for a platform-scoped role") if branch_id.present?
    when "organization"
      errors.add(:organization_id, "is required for an organization-scoped role") if organization_id.blank?
      errors.add(:branch_id, "must be blank for an organization-scoped role") if branch_id.present?
    when "branch"
      errors.add(:organization_id, "is required for a branch-scoped role") if organization_id.blank?
      errors.add(:branch_id, "is required for a branch-scoped role") if branch_id.blank?
    end
  end
end
