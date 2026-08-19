class Address < ApplicationRecord
  encrypts :contact_phone_encrypted
  alias_attribute :contact_phone, :contact_phone_encrypted

  belongs_to :customer
  belongs_to :city

  validates :recipient_name, :original_text, presence: true
  validates :location, presence: true

  before_save :unset_other_defaults, if: -> { is_default? && is_default_changed? }

  # Informational, not a hard validation — an address can be saved even if
  # nothing currently covers it (section 4.4: "determinar cobertura", not
  # "rechazar si no hay cobertura").
  def covered?
    Geography::CheckCoverage.call(longitude: location.x, latitude: location.y).exists?
  end

  def archived?
    archived_at.present?
  end

  private

  def unset_other_defaults
    Address.where(customer_id: customer_id).where.not(id: id).where(is_default: true).update_all(is_default: false)
  end
end
