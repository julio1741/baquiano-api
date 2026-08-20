class Vehicle < ApplicationRecord
  encrypts :plate_encrypted

  alias_attribute :plate, :plate_encrypted

  belongs_to :courier

  enum :vehicle_type, { motorcycle: "motorcycle", bicycle: "bicycle", car: "car", walking: "walking",
                         other: "other" }, validate: true

  before_validation :set_plate_digest

  private

  def set_plate_digest
    self.plate_digest = BlindIndex.digest(plate)
  end
end
