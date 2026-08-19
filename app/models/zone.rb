class Zone < ApplicationRecord
  belongs_to :city

  validates :name, :code, presence: true
  validates :geometry, presence: true
end
