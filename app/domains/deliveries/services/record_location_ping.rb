module Deliveries
  class RecordLocationPing
    def self.call(...) = new(...).call

    def initialize(courier:, latitude:, longitude:, device_recorded_at:, source:, delivery: nil,
                   accuracy_meters: nil, speed_meters_per_second: nil, heading_degrees: nil)
      @courier = courier
      @latitude = latitude
      @longitude = longitude
      @device_recorded_at = device_recorded_at
      @source = source
      @delivery = delivery
      @accuracy_meters = accuracy_meters
      @speed_meters_per_second = speed_meters_per_second
      @heading_degrees = heading_degrees
    end

    def call
      LocationPing.create!(
        courier: @courier, delivery: @delivery,
        location: RGeo::Geographic.spherical_factory(srid: 4326).point(@longitude, @latitude),
        device_recorded_at: @device_recorded_at, server_received_at: Time.current, source: @source,
        accuracy_meters: @accuracy_meters, speed_meters_per_second: @speed_meters_per_second,
        heading_degrees: @heading_degrees
      )
    end
  end
end
