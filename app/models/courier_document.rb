class CourierDocument < ApplicationRecord
  encrypts :document_number_encrypted

  alias_attribute :document_number, :document_number_encrypted

  belongs_to :courier
  belongs_to :reviewed_by_user, class_name: "User", optional: true

  enum :status, { pending: "pending", approved: "approved", rejected: "rejected" }, validate: true

  validates :document_type, :attachment_reference, presence: true

  before_validation :set_document_number_digest

  private

  def set_document_number_digest
    self.document_number_digest = BlindIndex.digest(document_number)
  end
end
