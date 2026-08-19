class ProductVariant < ApplicationRecord
  belongs_to :product

  validates :sku, :name, presence: true
  validates :price_amount, numericality: { greater_than_or_equal_to: 0 }
  validates :currency, presence: true, format: { with: /\A[A-Z]{3}\z/ }
end
