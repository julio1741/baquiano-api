class InventoryItem < ApplicationRecord
  belongs_to :branch
  belongs_to :product, optional: true
  belongs_to :product_variant, optional: true
  belongs_to :updated_by_user, class_name: "User"

  enum :availability_status, { available: "available", low_stock: "low_stock", unavailable: "unavailable" },
       validate: true

  validate :exactly_one_target

  private

  def exactly_one_target
    return if product_id.present? != product_variant_id.present?

    errors.add(:base, "must reference exactly one of product or product_variant")
  end
end
