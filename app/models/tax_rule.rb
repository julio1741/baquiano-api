# Rates are never invented here — they only exist once someone enters them
# after real fiscal/legal validation (section 4.6 of the spec).
class TaxRule < ApplicationRecord
  belongs_to :organization, optional: true
  has_many :products, dependent: :restrict_with_error

  validates :name, presence: true
  validates :rate_basis_points, numericality: { in: 0..10_000 }
  validates :valid_from, presence: true

  validate :valid_until_after_valid_from

  private

  def valid_until_after_valid_from
    return if valid_until.blank? || valid_from.blank?

    errors.add(:valid_until, "must be after valid_from") if valid_until < valid_from
  end
end
