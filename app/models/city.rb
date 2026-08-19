class City < ApplicationRecord
  has_many :zones, dependent: :restrict_with_error
  has_many :service_areas, dependent: :restrict_with_error

  validates :name, :state_name, :country_code, :timezone, presence: true
end
