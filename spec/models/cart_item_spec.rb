require "rails_helper"

RSpec.describe CartItem, type: :model do
  it "rejects a product from a different branch than the cart's" do
    cart = create(:cart)
    other_product = create(:product)

    item = build(:cart_item, cart: cart, product: other_product)

    expect(item).not_to be_valid
    expect(item.errors[:product]).to be_present
  end

  it "rejects a variant that belongs to a different product" do
    cart = create(:cart)
    product = create(:product, catalog: create(:catalog, branch: cart.branch))
    other_variant = create(:product_variant)

    item = build(:cart_item, cart: cart, product: product, product_variant: other_variant)

    expect(item).not_to be_valid
    expect(item.errors[:product_variant]).to be_present
  end

  describe "#line_total" do
    it "multiplies (unit price + modifiers per unit) by quantity" do
      item = create(:cart_item, quantity: 3, unit_price_amount_snapshot: 1_000)
      modifier = create(:modifier, modifier_group: create(:modifier_group, product: item.product))
      create(:cart_item_modifier, cart_item: item, modifier: modifier, quantity: 2,
                                   additional_price_amount_snapshot: 100)

      expect(item.line_total).to eq((1_000 + (100 * 2)) * 3)
    end
  end
end
