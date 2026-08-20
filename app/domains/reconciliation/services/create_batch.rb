module Reconciliation
  # Matches internal PaymentTransaction rows for the period against an
  # externally-provided record set (e.g. a manually uploaded bank/provider
  # statement — there's no real gateway integration, section 16). Anything
  # on one side without a counterpart on the other still gets a
  # ReconciliationItem, expected/actual defaulting to 0 on whichever side
  # is missing, so the difference is visible rather than silently dropped.
  class CreateBatch
    def self.call(...) = new(...).call

    # external_records: [{ external_reference:, amount: }]
    def initialize(provider:, payment_method:, currency:, period_start:, period_end:, started_by:, external_records:)
      @provider = provider
      @payment_method = payment_method
      @currency = currency
      @period_start = period_start
      @period_end = period_end
      @started_by = started_by
      @external_records = external_records
    end

    def call
      ActiveRecord::Base.transaction do
        batch = ReconciliationBatch.create!(
          provider: @provider, payment_method: @payment_method, currency: @currency, period_start: @period_start,
          period_end: @period_end, started_by_user: @started_by, started_at: Time.current, status: "open"
        )

        internal_by_ref = internal_transactions.index_by(&:provider_transaction_id)

        @external_records.each do |record|
          ref = record.fetch(:external_reference)
          txn = internal_by_ref.delete(ref)
          ReconciliationItem.create!(
            reconciliation_batch: batch, payment_transaction: txn, external_reference: ref,
            expected_amount: txn&.amount || 0, actual_amount: record.fetch(:amount), currency: @currency
          )
        end

        internal_by_ref.each_value do |txn|
          ReconciliationItem.create!(
            reconciliation_batch: batch, payment_transaction: txn, external_reference: txn.provider_transaction_id,
            expected_amount: txn.amount, actual_amount: 0, currency: @currency
          )
        end

        batch.recompute_totals!
        batch
      end
    end

    private

    def internal_transactions
      PaymentTransaction.joins(:payment_intent)
        .where(payment_intents: { payment_method: @payment_method, currency: @currency })
        .where(occurred_at: @period_start.beginning_of_day..@period_end.end_of_day)
        .where.not(provider_transaction_id: nil)
    end
  end
end
