module Support
  # Deliberately lighter-weight than Orders::TransitionOrder/
  # Deliveries::TransitionDelivery — no dedicated support team exists yet
  # (section 4.16), so this only guards against nonsensical status jumps
  # (e.g. open straight to closed, skipping resolution), not per-transition
  # actor/permission rules. Any staff member with support:manage can drive
  # any allowed transition; the case's assigned_to_user is informational.
  class TransitionCase
    ALLOWED_TRANSITIONS = {
      "open" => %w[in_progress closed],
      "in_progress" => %w[waiting_customer waiting_merchant waiting_courier resolved closed],
      "waiting_customer" => %w[in_progress closed],
      "waiting_merchant" => %w[in_progress closed],
      "waiting_courier" => %w[in_progress closed],
      "resolved" => %w[in_progress closed],
      "closed" => %w[open]
    }.freeze

    def self.call(...) = new(...).call

    def initialize(support_case:, to_status:, resolution: nil)
      @support_case = support_case
      @to_status = to_status.to_s
      @resolution = resolution
    end

    def call
      from_status = @support_case.status
      allowed = ALLOWED_TRANSITIONS.fetch(from_status, [])
      unless allowed.include?(@to_status)
        raise ConflictError.new("cannot transition from #{from_status} to #{@to_status}", code: "invalid_transition")
      end

      attrs = { status: @to_status }
      attrs[:resolution] = @resolution if @resolution.present?
      attrs[:resolved_at] = Time.current if @to_status == "resolved"
      attrs[:closed_at] = Time.current if @to_status == "closed"

      @support_case.status_change_authorized = true
      @support_case.update!(attrs)
      @support_case
    end
  end
end
