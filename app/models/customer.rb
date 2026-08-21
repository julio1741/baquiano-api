class Customer < ApplicationRecord
  belongs_to :user
  belongs_to :default_address, class_name: "Address", optional: true
  has_many :addresses, dependent: :destroy
  has_many :carts, dependent: :restrict_with_error
  has_many :quotes, dependent: :restrict_with_error
  has_many :orders, dependent: :restrict_with_error
  has_many :payment_intents, dependent: :restrict_with_error
  has_many :support_cases, dependent: :restrict_with_error

  enum :status, { active: "active", suspended: "suspended" }, validate: true

  validates :risk_level, presence: true
  validates :total_completed_orders, numericality: { greater_than_or_equal_to: 0 }
end
