class Cart < ApplicationRecord
  belongs_to :customer
  belongs_to :branch
  has_many :cart_items, dependent: :destroy
  has_many :quotes, dependent: :restrict_with_error

  enum :status, { active: "active", converted: "converted", abandoned: "abandoned", expired: "expired" },
       validate: true

  validates :currency, presence: true, format: { with: /\A[A-Z]{3}\z/ }
  validates :expires_at, presence: true

  def expired?
    expires_at <= Time.current
  end
end
