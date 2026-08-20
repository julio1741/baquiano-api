# Append-only (section 4.11) — corrections are reversals or compensating
# entries, never edits. See Ledger::PostTransaction, which is the only
# place these (and their LedgerEntry rows) ever get created.
class LedgerTransaction < ApplicationRecord
  belongs_to :reversal_of_transaction, class_name: "LedgerTransaction", optional: true
  belongs_to :created_by_user, class_name: "User", optional: true
  has_many :ledger_entries, dependent: :restrict_with_error

  validates :transaction_type, :reference_type, :reference_id, :idempotency_key, :effective_at, :posted_at,
            presence: true
  validates :idempotency_key, uniqueness: true

  def readonly?
    persisted?
  end
end
