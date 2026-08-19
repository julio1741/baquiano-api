class ModifierGroup < ApplicationRecord
  belongs_to :product
  has_many :modifiers, dependent: :destroy

  validates :name, presence: true
  validates :minimum_selections, numericality: { greater_than_or_equal_to: 0 }

  validate :maximum_gte_minimum

  private

  def maximum_gte_minimum
    return if maximum_selections.nil? || minimum_selections.nil?

    errors.add(:maximum_selections, "must be >= minimum_selections") if maximum_selections < minimum_selections
  end
end
