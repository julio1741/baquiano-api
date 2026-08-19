class Product < ApplicationRecord
  belongs_to :catalog
  belongs_to :category
  belongs_to :tax_rule, optional: true
  has_many :product_variants, dependent: :destroy
  has_many :modifier_groups, dependent: :destroy
  has_many :inventory_items, dependent: :destroy

  validates :sku, :name, :product_type, presence: true
  validates :base_price_amount, numericality: { greater_than_or_equal_to: 0 }
  validates :currency, presence: true, format: { with: /\A[A-Z]{3}\z/ }

  validate :category_in_same_catalog
  validate :prescription_products_gated_by_configuration

  private

  def category_in_same_catalog
    return if category.nil?

    errors.add(:category, "must belong to the same catalog") if category.catalog_id != catalog_id
  end

  def prescription_products_gated_by_configuration
    return unless prescription_required? && active?
    return if Rails.application.config.x.prescription_sales_enabled

    errors.add(:active, "cannot be true for a prescription_required product until legal/regulatory " \
                         "configuration allows it (config.x.prescription_sales_enabled)")
  end
end
