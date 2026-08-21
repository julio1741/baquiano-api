class NotificationPreference < ApplicationRecord
  belongs_to :user

  validates :notification_type, presence: true, uniqueness: { scope: :user_id }
end
