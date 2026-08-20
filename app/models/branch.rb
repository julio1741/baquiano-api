class Branch < ApplicationRecord
  encrypts :phone_encrypted
  encrypts :email_encrypted
  alias_attribute :phone, :phone_encrypted
  alias_attribute :email, :email_encrypted

  belongs_to :organization
  belongs_to :merchant
  has_many :business_hours, dependent: :destroy
  has_many :special_business_hours, dependent: :destroy
  has_many :service_areas, dependent: :nullify
  has_many :catalogs, dependent: :restrict_with_error
  has_many :inventory_items, dependent: :destroy
  has_many :role_assignments, dependent: :restrict_with_error
  has_many :orders, dependent: :restrict_with_error

  enum :delivery_model, { baquiano: "baquiano", merchant: "merchant", hybrid: "hybrid" }, validate: true
  enum :status, { pending: "pending", active: "active", suspended: "suspended" }, validate: true

  validates :name, :slug, :address_text, presence: true
  validates :slug, format: { with: /\A[a-z0-9-]+\z/ }
  validates :location, presence: true

  def paused?
    paused_at.present?
  end

  def pause!(reason: nil)
    update!(paused_at: Time.current, pause_reason: reason)
  end

  def resume!
    update!(paused_at: nil, pause_reason: nil)
  end
end
