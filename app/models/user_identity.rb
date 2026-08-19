class UserIdentity < ApplicationRecord
  belongs_to :user

  validates :provider, :provider_subject, presence: true
  validates :provider_subject, uniqueness: { scope: :provider }
end
