class CourierAvailability < ApplicationRecord
  belongs_to :courier
  belongs_to :zone, optional: true

  enum :status, { online: "online", offline: "offline", paused: "paused", busy: "busy" }, validate: true

  validates :started_at, presence: true

  def open? = ended_at.nil?
end
