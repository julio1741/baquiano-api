module Reconciliation
  class CompleteBatch
    def self.call(...) = new(...).call

    def initialize(batch:, completed_by:)
      @batch = batch
      @completed_by = completed_by
    end

    def call
      if @batch.reconciliation_items.where.not(status: %w[matched resolved]).exists?
        raise ConflictError.new("all items must be matched or resolved before closing this batch",
                                 code: "unresolved_items")
      end

      @batch.update!(status: "completed", completed_by_user: @completed_by, completed_at: Time.current)
      @batch
    end
  end
end
