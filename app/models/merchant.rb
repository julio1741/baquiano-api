class Merchant < ApplicationRecord
  belongs_to :organization
  has_many :branches, dependent: :restrict_with_error
  has_many :settlements, as: :beneficiary, dependent: :restrict_with_error

  enum :vertical, { restaurant: "restaurant", grocery: "grocery", pharmacy: "pharmacy" }, validate: true
  enum :status, { pending: "pending", active: "active", suspended: "suspended" }, validate: true

  validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9-]+\z/ }
  validates :commission_rate_basis_points, numericality: { in: 0..10_000 }, allow_nil: true
end
