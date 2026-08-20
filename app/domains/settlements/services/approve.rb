module Settlements
  class Approve
    def self.call(...) = new(...).call

    def initialize(settlement:, approved_by:)
      @settlement = settlement
      @approved_by = approved_by
    end

    def call
      raise ConflictError.new("this settlement is not pending approval", code: "not_pending") unless @settlement.pending?

      @settlement.status_change_authorized = true
      @settlement.update!(status: "approved", approved_by_user: @approved_by)
      @settlement
    end
  end
end
