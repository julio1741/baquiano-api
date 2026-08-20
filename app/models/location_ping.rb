# Append-only telemetry — never updated after creation (section 4.14: no
# updated_at column even exists).
class LocationPing < ApplicationRecord
  belongs_to :courier
  belongs_to :delivery, optional: true

  validates :location, :device_recorded_at, :server_received_at, :source, presence: true

  def readonly?
    persisted?
  end
end
