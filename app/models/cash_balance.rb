class CashBalance < ApplicationRecord
  belongs_to :courier

  validates :currency, presence: true
  validates :exposure_limit, numericality: { greater_than_or_equal_to: 0 }
  validates :amount_held, numericality: { greater_than_or_equal_to: 0 }

  def over_limit?
    amount_held > exposure_limit
  end
end
