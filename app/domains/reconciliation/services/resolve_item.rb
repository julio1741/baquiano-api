module Reconciliation
  class ResolveItem
    def self.call(...) = new(...).call

    def initialize(item:, resolved_by:, resolution_code:, resolution_notes: nil)
      @item = item
      @resolved_by = resolved_by
      @resolution_code = resolution_code
      @resolution_notes = resolution_notes
    end

    def call
      @item.resolve!(resolved_by: @resolved_by, resolution_code: @resolution_code,
                      resolution_notes: @resolution_notes)
      @item
    end
  end
end
