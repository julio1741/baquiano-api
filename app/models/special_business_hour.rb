class SpecialBusinessHour < ApplicationRecord
  belongs_to :branch

  validates :date, presence: true
  validate :hours_present_unless_closed

  private

  def hours_present_unless_closed
    return if is_closed

    errors.add(:opens_at, "is required when not closed") if opens_at.blank?
    errors.add(:closes_at, "is required when not closed") if closes_at.blank?
  end
end
