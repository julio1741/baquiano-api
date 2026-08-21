class FeatureFlag < ApplicationRecord
  belongs_to :created_by_user, class_name: "User"
  belongs_to :updated_by_user, class_name: "User"

  validates :key, presence: true, uniqueness: true
end
