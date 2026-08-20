# Append-only audit trail — written exclusively by Orders::TransitionOrder.
class OrderStatusHistory < ApplicationRecord
  belongs_to :order
  belongs_to :actor_user, class_name: "User", optional: true

  validates :to_status, :actor_type, :occurred_at, presence: true

  def readonly?
    persisted?
  end
end
