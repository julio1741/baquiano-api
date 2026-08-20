class Organization < ApplicationRecord
  encrypts :tax_identifier_encrypted
  encrypts :contact_phone_encrypted
  encrypts :contact_email_encrypted

  alias_attribute :tax_identifier, :tax_identifier_encrypted
  alias_attribute :contact_phone, :contact_phone_encrypted
  alias_attribute :contact_email, :contact_email_encrypted

  has_many :merchants, dependent: :restrict_with_error
  has_many :branches, dependent: :restrict_with_error
  has_many :couriers, dependent: :restrict_with_error
  has_many :roles, dependent: :restrict_with_error
  has_many :role_assignments, dependent: :restrict_with_error

  enum :organization_type, { merchant: "merchant", platform: "platform", fleet_partner: "fleet_partner" }, validate: true
  enum :status, { pending: "pending", active: "active", suspended: "suspended" }, validate: true

  validates :legal_name, :display_name, presence: true
  validates :default_currency, presence: true, format: { with: /\A[A-Z]{3}\z/ }
  validates :tax_identifier_digest, uniqueness: true, allow_nil: true

  before_validation :set_tax_identifier_digest

  def suspend!(reason:)
    update!(status: "suspended", suspended_at: Time.current, suspension_reason: reason)
  end

  def approve!
    update!(status: "active", approved_at: Time.current)
  end

  private

  def set_tax_identifier_digest
    self.tax_identifier_digest = tax_identifier.present? ? BlindIndex.digest(tax_identifier.strip) : nil
  end
end
