class LedgerEntry < ApplicationRecord
  belongs_to :ledger_transaction
  belongs_to :ledger_account

  enum :direction, { debit: "debit", credit: "credit" }, validate: true

  validates :amount, numericality: { greater_than: 0 }
  validates :currency, presence: true

  def readonly?
    persisted?
  end
end
