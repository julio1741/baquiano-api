module Ledger
  # The only way a LedgerTransaction/LedgerEntry ever gets created —
  # enforces section 4.11's core invariant (sum of debits == sum of
  # credits, per currency) before anything is persisted. Idempotent by
  # idempotency_key: replaying the same key returns the original
  # transaction rather than posting a second time.
  class PostTransaction
    def self.call(...) = new(...).call

    # entries: array of { account:, direction: "debit"|"credit", amount:, currency: }
    def initialize(transaction_type:, reference_type:, reference_id:, entries:, idempotency_key:,
                   description: nil, effective_at: Time.current, created_by: nil, metadata: {})
      @transaction_type = transaction_type
      @reference_type = reference_type
      @reference_id = reference_id
      @entries = entries
      @idempotency_key = idempotency_key
      @description = description
      @effective_at = effective_at
      @created_by = created_by
      @metadata = metadata
    end

    def call
      existing = LedgerTransaction.find_by(idempotency_key: @idempotency_key)
      return existing if existing

      validate_balanced!

      ActiveRecord::Base.transaction do
        ledger_transaction = LedgerTransaction.create!(
          transaction_type: @transaction_type, reference_type: @reference_type, reference_id: @reference_id,
          description: @description, idempotency_key: @idempotency_key, effective_at: @effective_at,
          posted_at: Time.current, created_by_user: @created_by, metadata: @metadata
        )

        @entries.each do |entry|
          LedgerEntry.create!(
            ledger_transaction: ledger_transaction, ledger_account: entry.fetch(:account),
            direction: entry.fetch(:direction), amount: entry.fetch(:amount), currency: entry.fetch(:currency)
          )
        end

        ledger_transaction
      end
    end

    private

    def validate_balanced!
      if @entries.size < 2
        raise ValidationError.new("a ledger transaction needs at least 2 entries", code: "ledger_unbalanced")
      end

      @entries.group_by { |e| e.fetch(:currency) }.each do |currency, entries|
        debits = entries.select { |e| e.fetch(:direction) == "debit" }.sum { |e| e.fetch(:amount) }
        credits = entries.select { |e| e.fetch(:direction) == "credit" }.sum { |e| e.fetch(:amount) }
        next if debits == credits

        raise ValidationError.new("debits (#{debits}) must equal credits (#{credits}) for #{currency}",
                                   code: "ledger_unbalanced")
      end
    end
  end
end
