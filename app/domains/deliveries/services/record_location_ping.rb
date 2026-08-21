module Deliveries
  class RecordLocationPing
    IMPOSSIBLE_SPEED_KMH = 150.0

    def self.call(...) = new(...).call

    def initialize(courier:, latitude:, longitude:, device_recorded_at:, source:, delivery: nil,
                   accuracy_meters: nil, speed_meters_per_second: nil, heading_degrees: nil,
                   simulated_location_suspected: false)
      @courier = courier
      @latitude = latitude
      @longitude = longitude
      @device_recorded_at = device_recorded_at
      @source = source
      @delivery = delivery
      @accuracy_meters = accuracy_meters
      @speed_meters_per_second = speed_meters_per_second
      @heading_degrees = heading_degrees
      @simulated_location_suspected = ActiveModel::Type::Boolean.new.cast(simulated_location_suspected)
    end

    def call
      # By device_recorded_at, not insertion order — section 10, scenario
      # 16 ("ubicación duplicada o fuera de orden") means pings can arrive
      # out of sequence; comparing by claimed time is what makes an
      # "impossible speed" check meaningful either way.
      previous_ping = @courier.location_pings.order(device_recorded_at: :desc).first

      ping = LocationPing.create!(
        courier: @courier, delivery: @delivery,
        location: RGeo::Geographic.spherical_factory(srid: 4326).point(@longitude, @latitude),
        device_recorded_at: @device_recorded_at, server_received_at: Time.current, source: @source,
        accuracy_meters: @accuracy_meters, speed_meters_per_second: @speed_meters_per_second,
        heading_degrees: @heading_degrees, simulated_location_suspected: @simulated_location_suspected
      )

      flag_simulated_location(ping)
      flag_impossible_speed(previous_ping, ping)

      ping
    end

    private

    # The mock-location detection itself happens on the device (e.g.
    # Android's isFromMockProvider()) — the client just tells us. No
    # server-side spoof detection exists; this only routes an already
    # client-reported signal into the fraud pipeline (section 4.17's
    # "GPS simulado").
    def flag_simulated_location(ping)
      return unless @simulated_location_suspected

      Risk::RecordSignal.call(
        subject: @courier, signal_type: "simulated_gps_location", score: 60.0, severity: "medium",
        evidence: { location_ping_id: ping.id, delivery_id: @delivery&.id }
      )
    end

    def flag_impossible_speed(previous_ping, ping)
      return unless previous_ping
      return if ping.device_recorded_at <= previous_ping.device_recorded_at

      seconds_elapsed = ping.device_recorded_at - previous_ping.device_recorded_at
      speed_kmh = (distance_meters(previous_ping.location, ping.location) / seconds_elapsed) * 3.6
      return if speed_kmh <= IMPOSSIBLE_SPEED_KMH

      Risk::RecordSignal.call(
        subject: @courier, signal_type: "impossible_geographic_speed", score: 70.0, severity: "high",
        evidence: { location_ping_id: ping.id, previous_location_ping_id: previous_ping.id,
                    implied_speed_kmh: speed_kmh.round(1) }
      )
    end

    # Real geographic distance via PostGIS (ST_Distance on geography), not
    # a Ruby approximation — same pattern as Pricing::GenerateQuote.
    def distance_meters(point_a, point_b)
      sql = ActiveRecord::Base.sanitize_sql_array([
        "SELECT ST_Distance(ST_SetSRID(ST_MakePoint(?, ?), 4326)::geography, " \
        "ST_SetSRID(ST_MakePoint(?, ?), 4326)::geography)",
        point_a.x, point_a.y, point_b.x, point_b.y
      ])
      ActiveRecord::Base.connection.select_value(sql).to_f
    end
  end
end
