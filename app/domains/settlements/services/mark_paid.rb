module Settlements
  class MarkPaid
    def self.call(...) = new(...).call

    def initialize(settlement:, payment_reference: nil)
      @settlement = settlement
      @payment_reference = payment_reference
    end

    def call
      unless @settlement.approved?
        raise ConflictError.new("this settlement must be approved before it can be paid", code: "not_approved")
      end

      ActiveRecord::Base.transaction do
        @settlement.status_change_authorized = true
        @settlement.update!(status: "paid", paid_at: Time.current, payment_reference: @payment_reference)

        Ledger::PostTransaction.call(
          transaction_type: "settlement_paid", reference_type: "Settlement", reference_id: @settlement.id,
          idempotency_key: "settlement_paid:#{@settlement.id}",
          description: "Settlement paid to #{@settlement.beneficiary_type} #{@settlement.beneficiary_id}",
          entries: [
            { account: payable_account, direction: "debit", amount: @settlement.net_amount,
              currency: @settlement.currency },
            { account: cash_clearing_account, direction: "credit", amount: @settlement.net_amount,
              currency: @settlement.currency }
          ]
        )
      end
      @settlement
    end

    private

    def cash_clearing_account
      LedgerAccount.find_or_create_by!(account_code: "platform:cash_clearing") do |account|
        account.account_type = "asset"
        account.currency = @settlement.currency
      end
    end

    def payable_account
      case @settlement.beneficiary
      when ::Merchant
        LedgerAccount.find_or_create_by!(account_code: "merchant:#{@settlement.beneficiary_id}:payable") do |account|
          account.account_type = "liability"
          account.currency = @settlement.currency
          account.owner = @settlement.beneficiary
        end
      when ::Courier
        LedgerAccount.find_or_create_by!(account_code: "platform:delivery_fee_payable") do |account|
          account.account_type = "liability"
          account.currency = @settlement.currency
        end
      else
        raise ValidationError.new("unsupported settlement beneficiary", code: "unsupported_beneficiary")
      end
    end
  end
end
