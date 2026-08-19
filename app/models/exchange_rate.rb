class ExchangeRate < ApplicationRecord
  belongs_to :created_by_user, class_name: "User"

  validates :base_currency, :quote_currency, format: { with: /\A[A-Z]{3}\z/ }
  validates :source, :rate_type, presence: true
  validates :rate_numerator, :rate_denominator, numericality: { greater_than: 0 }
  validates :effective_at, presence: true

  def convert(amount_minor_units)
    (amount_minor_units * rate_numerator) / rate_denominator
  end
end
