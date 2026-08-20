module Ledger
  # Simplified on purpose: the whole refunded amount is reversed against
  # the merchant's own payable, rather than proportionally splitting it
  # back across subtotal/tax/delivery_fee/commission the way the original
  # settlement was composed. Accurately unwinding a partial refund across
  # those original components is a real accounting policy decision this
  # MVP hasn't made — see docs/architecture/decisions.md.
  class RecordRefundEntries
    def self.call(...) = new(...).call

    def initialize(refund:)
      @refund = refund
    end

    def call
      Ledger::PostTransaction.call(
        transaction_type: "refund",
        reference_type: "Refund",
        reference_id: @refund.id,
        idempotency_key: "refund:#{@refund.id}",
        description: "Refund for order #{@refund.order.public_number}",
        entries: [
          { account: merchant_payable_account, direction: "debit", amount: @refund.amount, currency: @refund.currency },
          { account: cash_clearing_account, direction: "credit", amount: @refund.amount, currency: @refund.currency }
        ]
      )
    end

    private

    def cash_clearing_account
      LedgerAccount.find_or_create_by!(account_code: "platform:cash_clearing") do |account|
        account.account_type = "asset"
        account.currency = @refund.currency
      end
    end

    def merchant_payable_account
      order = @refund.order
      LedgerAccount.find_or_create_by!(account_code: "merchant:#{order.merchant_id}:payable") do |account|
        account.account_type = "liability"
        account.currency = @refund.currency
        account.owner = order.merchant
      end
    end
  end
end
