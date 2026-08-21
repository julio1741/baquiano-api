# destination_digest, not the raw phone/email/push token — section 4.15:
# "No incluir datos personales o detalles sensibles innecesarios en push
# notifications." provider is always "log" (Notifications::LogProvider) —
# no real push/SMS/email integration, section 16.
class Notification < ApplicationRecord
  belongs_to :user
  belongs_to :order, optional: true

  enum :channel, { push: "push", sms: "sms", email: "email", internal: "internal" }, validate: true
  enum :status, { pending: "pending", sent: "sent", delivered: "delivered", failed: "failed" }, validate: true

  validates :template_code, :scheduled_at, :idempotency_key, presence: true
  validates :idempotency_key, uniqueness: { scope: :user_id }
end
