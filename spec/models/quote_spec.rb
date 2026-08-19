require "rails_helper"

RSpec.describe Quote, type: :model do
  it "requires total_amount to equal subtotal - discount + tax + delivery_fee + service_fee" do
    quote = build(:quote, subtotal_amount: 1_000, discount_amount: 100, tax_amount: 160,
                          delivery_fee_amount: 150, service_fee_amount: 0, total_amount: 1_210)

    expect(quote).to be_valid
  end

  it "rejects a total that doesn't match its components" do
    quote = build(:quote, subtotal_amount: 1_000, discount_amount: 0, tax_amount: 0,
                          delivery_fee_amount: 0, service_fee_amount: 0, total_amount: 999)

    expect(quote).not_to be_valid
    expect(quote.errors[:total_amount]).to be_present
  end

  it "enforces one idempotency_key per customer" do
    existing = create(:quote, idempotency_key: "dup")

    duplicate = build(:quote, customer: existing.customer, idempotency_key: "dup")

    expect(duplicate).not_to be_valid
  end
end
