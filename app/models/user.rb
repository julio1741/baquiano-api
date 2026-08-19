class User < ApplicationRecord
  encrypts :phone_number_encrypted
  encrypts :email_encrypted

  alias_attribute :phone_number, :phone_number_encrypted
  alias_attribute :email, :email_encrypted

  has_many :user_identities, dependent: :destroy
  has_many :sessions, dependent: :destroy
  has_many :devices, dependent: :destroy
  has_many :role_assignments, dependent: :destroy

  enum :status, {
    pending_verification: "pending_verification",
    active: "active",
    locked: "locked",
    disabled: "disabled"
  }, validate: true

  validates :phone_country_code, presence: true
  validates :first_name, :last_name, presence: true
  validates :phone_number, presence: true
  validates :phone_number_digest, presence: true, uniqueness: true
  validates :email_digest, uniqueness: true, allow_nil: true

  before_validation :set_phone_number_digest
  before_validation :set_email_digest

  def self.find_by_phone(country_code, number)
    find_by(phone_number_digest: BlindIndex.digest(Phone.e164(country_code, number)))
  end

  def authenticatable?
    active? && locked_at.nil? && disabled_at.nil?
  end

  private

  def set_phone_number_digest
    return if phone_country_code.blank? || phone_number.blank?

    self.phone_number_digest = BlindIndex.digest(Phone.e164(phone_country_code, phone_number))
  end

  def set_email_digest
    self.email_digest = email.present? ? BlindIndex.digest(email.strip.downcase) : nil
  end
end
