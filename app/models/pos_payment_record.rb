class PosPaymentRecord < ApplicationRecord
  encrypts :terminal_identifier_encrypted
  encrypts :acquiring_account_reference_encrypted

  alias_attribute :terminal_identifier, :terminal_identifier_encrypted
  alias_attribute :acquiring_account_reference, :acquiring_account_reference_encrypted

  belongs_to :payment_intent
  belongs_to :confirmed_by_user, class_name: "User"
  belongs_to :terminal_owner, polymorphic: true, optional: true

  enum :status, { confirmed: "confirmed", reversed: "reversed" }, validate: true

  validates :confirmed_at, presence: true
  validates :amount, numericality: { greater_than_or_equal_to: 0 }
end
