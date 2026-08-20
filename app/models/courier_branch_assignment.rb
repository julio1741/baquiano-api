class CourierBranchAssignment < ApplicationRecord
  belongs_to :courier
  belongs_to :branch

  validates :starts_at, presence: true
end
