class Permission < ApplicationRecord
  has_many :role_permissions, dependent: :destroy
  has_many :roles, through: :role_permissions

  validates :resource, :action, presence: true
  validates :code, presence: true, uniqueness: true, format: { with: /\A[a-z_]+:[a-z_]+\z/ }

  before_validation :derive_code

  private

  def derive_code
    self.code = "#{resource}:#{action}" if code.blank? && resource.present? && action.present?
  end
end
