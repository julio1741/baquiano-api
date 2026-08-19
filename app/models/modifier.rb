class Modifier < ApplicationRecord
  belongs_to :modifier_group

  validates :name, presence: true
  validates :additional_price_amount, numericality: { greater_than_or_equal_to: 0 }
  validates :currency, presence: true, format: { with: /\A[A-Z]{3}\z/ }
end
