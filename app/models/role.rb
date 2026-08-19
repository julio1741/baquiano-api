class Role < ApplicationRecord
  has_many :role_permissions, dependent: :destroy
  has_many :permissions, through: :role_permissions
  has_many :role_assignments

  enum :scope_type, { platform: "platform", organization: "organization", branch: "branch" }, validate: true

  validates :name, :code, presence: true

  validate :organization_id_matches_scope

  private

  def organization_id_matches_scope
    case scope_type
    when "platform"
      errors.add(:organization_id, "must be blank for platform-scoped roles") if organization_id.present?
    when "organization", "branch"
      errors.add(:organization_id, "is required for #{scope_type}-scoped roles") if organization_id.blank?
    end
  end
end
