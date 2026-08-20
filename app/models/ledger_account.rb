class LedgerAccount < ApplicationRecord
  belongs_to :organization, optional: true
  belongs_to :owner, polymorphic: true, optional: true
  has_many :ledger_entries, dependent: :restrict_with_error

  enum :account_type, { asset: "asset", liability: "liability", revenue: "revenue", expense: "expense",
                         equity: "equity", clearing: "clearing" }, validate: true
  enum :status, { active: "active", closed: "closed" }, validate: true

  validates :account_code, presence: true, uniqueness: true
  validates :currency, presence: true

  def balance
    credits = ledger_entries.where(direction: "credit").sum(:amount)
    debits = ledger_entries.where(direction: "debit").sum(:amount)
    normal_credit_balance? ? credits - debits : debits - credits
  end

  private

  def normal_credit_balance?
    %w[liability revenue equity].include?(account_type)
  end
end
