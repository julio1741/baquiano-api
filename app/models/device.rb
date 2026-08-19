class Device < ApplicationRecord
  encrypts :push_token_encrypted

  belongs_to :user
  has_many :sessions

  enum :platform, { ios: "ios", android: "android", web: "web" }, validate: true
  enum :app_type, {
    customer: "customer",
    courier: "courier",
    merchant: "merchant",
    admin: "admin"
  }, validate: true, prefix: true

  validates :installation_id, presence: true, uniqueness: { scope: :user_id }

  def blocked?
    blocked_at.present?
  end

  def trusted?
    trusted_at.present?
  end
end
