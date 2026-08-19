class Category < ApplicationRecord
  belongs_to :catalog
  belongs_to :parent_category, class_name: "Category", optional: true
  has_many :subcategories, class_name: "Category", foreign_key: :parent_category_id, inverse_of: :parent_category
  has_many :products, dependent: :restrict_with_error

  validates :name, presence: true

  validate :parent_in_same_catalog

  private

  def parent_in_same_catalog
    return if parent_category.nil?

    errors.add(:parent_category, "must belong to the same catalog") if parent_category.catalog_id != catalog_id
  end
end
