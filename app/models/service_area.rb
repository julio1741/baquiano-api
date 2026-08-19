# branch_id present: this polygon is one specific branch's own delivery
# coverage. branch_id nil: platform/zone-level "is Baquiano served here at
# all" coverage, not tied to a branch. See Geography::CheckCoverage.
class ServiceArea < ApplicationRecord
  belongs_to :branch, optional: true
  belongs_to :city

  validates :name, presence: true
  validates :geometry, presence: true

  scope :active, -> { where(active: true) }
  scope :covering, lambda { |longitude, latitude|
    where(
      "ST_Covers(geometry, ST_SetSRID(ST_MakePoint(?, ?), 4326)::geography)",
      longitude, latitude
    )
  }
end
