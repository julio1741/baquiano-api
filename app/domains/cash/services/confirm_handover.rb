module Cash
  class ConfirmHandover
    def self.call(...) = new(...).call

    def initialize(handover:)
      @handover = handover
    end

    def call
      raise ConflictError.new("this handover is not pending", code: "not_pending") unless @handover.pending?

      ActiveRecord::Base.transaction do
        @handover.update!(status: "confirmed", confirmed_at: Time.current)

        balance = CashBalance.find_by!(courier: @handover.courier, currency: @handover.currency)
        balance.update!(amount_held: balance.amount_held - @handover.amount, calculated_at: Time.current)
      end
      @handover
    end
  end
end
