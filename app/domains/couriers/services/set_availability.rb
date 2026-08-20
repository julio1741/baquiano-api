module Couriers
  # Only one open availability window per courier (DB-enforced, see
  # db/migrate/*_create_courier_availabilities.rb). "offline" closes the
  # current window; online/paused/busy update it in place if one is
  # already open (a courier flips between paused/busy many times during a
  # single session) or open a fresh one otherwise.
  class SetAvailability
    def self.call(...) = new(...).call

    def initialize(courier:, status:, zone_id: nil)
      @courier = courier
      @status = status.to_s
      @zone_id = zone_id
    end

    def call
      open = @courier.open_availability

      if @status == "offline"
        open&.update!(status: "offline", ended_at: Time.current)
        return open
      end

      if open
        open.update!(status: @status, zone_id: @zone_id || open.zone_id)
        open
      else
        @courier.courier_availabilities.create!(status: @status, zone_id: @zone_id, started_at: Time.current)
      end
    end
  end
end
