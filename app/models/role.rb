class Role < ApplicationRecord
  has_many :role_permissions, dependent: :destroy
  has_many :permissions, through: :role_permissions
  has_many :role_assignments

  # organization_id: which organization defined this custom role (nil for a
  # global/system role template usable by any organization — e.g.
  # "merchant_owner", assignable to staff at any merchant).
  #
  # scope_type: at what granularity ASSIGNMENTS of this role apply
  # (platform-wide / one organization / one branch). Independent of
  # organization_id above — a global role can very much have scope_type
  # "organization", meaning each assignment of it must specify which
  # organization it grants access to (see RoleAssignment's own validation).
  enum :scope_type, { platform: "platform", organization: "organization", branch: "branch" }, validate: true

  validates :name, :code, presence: true
end
