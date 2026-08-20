require "rails_helper"

RSpec.describe "Customer orders", type: :request do
  let(:city) { create(:city) }
  let(:organization) { create(:organization) }
  let(:branch) { create(:branch, organization: organization) }
  let(:catalog) { create(:catalog, branch: branch) }
  let(:category) { create(:category, catalog: catalog) }
  let(:product) { create(:product, catalog: catalog, category: category, base_price_amount: 1_000, currency: "VES") }
  let(:customer_user) { create(:user) }
  let(:headers) { auth_headers_for(customer_user, app_type: "customer") }

  before { Customers::EnsureProfile.call(user: customer_user) }

  def build_quote(idempotency_key: "quote-1")
    post "/api/v1/customer/branches/#{branch.id}/cart", headers: headers
    cart_id = response.parsed_body["id"]

    post "/api/v1/customer/carts/#{cart_id}/items", params: { product_id: product.id, quantity: 2 },
                                                     headers: headers, as: :json

    address = create(:address, customer: customer_user.customer, city: city)
    post "/api/v1/customer/carts/#{cart_id}/quotes",
         params: { address_id: address.id, idempotency_key: idempotency_key }, headers: headers, as: :json
    response.parsed_body["id"]
  end

  describe "POST /api/v1/customer/quotes/:quote_id/orders" do
    it "places an order from a quote, snapshotting items" do
      quote_id = build_quote

      post "/api/v1/customer/quotes/#{quote_id}/orders",
           params: { payment_method: "cash", idempotency_key: "order-1" }, headers: headers, as: :json

      expect(response).to have_http_status(:created)
      body = response.parsed_body
      expect(body["current_status"]).to eq("merchant_pending")
      expect(body["items"].first["quantity"]).to eq(2)
      expect(body["total_amount"]).to eq(body["subtotal_amount"] + body["tax_amount"] + body["delivery_fee_amount"])
    end

    it "is idempotent for the same idempotency_key" do
      quote_id = build_quote

      post "/api/v1/customer/quotes/#{quote_id}/orders",
           params: { payment_method: "cash", idempotency_key: "same-key" }, headers: headers, as: :json
      first_id = response.parsed_body["id"]

      post "/api/v1/customer/quotes/#{quote_id}/orders",
           params: { payment_method: "cash", idempotency_key: "same-key" }, headers: headers, as: :json

      expect(response.parsed_body["id"]).to eq(first_id)
      expect(Order.count).to eq(1)
    end

    it "denies placing an order from someone else's quote" do
      quote_id = build_quote
      other_headers = auth_headers_for(create(:user), app_type: "customer")

      post "/api/v1/customer/quotes/#{quote_id}/orders",
           params: { payment_method: "cash", idempotency_key: "order-x" }, headers: other_headers, as: :json

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "listing and viewing orders" do
    it "lists only my own orders and shows one in detail" do
      quote_id = build_quote
      post "/api/v1/customer/quotes/#{quote_id}/orders",
           params: { payment_method: "cash", idempotency_key: "order-2" }, headers: headers, as: :json
      order_id = response.parsed_body["id"]

      other_order = create(:order)

      get "/api/v1/customer/orders", headers: headers
      ids = response.parsed_body.map { |o| o["id"] }
      expect(ids).to include(order_id)
      expect(ids).not_to include(other_order.id)

      get "/api/v1/customer/orders/#{order_id}", headers: headers
      expect(response.parsed_body["public_number"]).to be_present
    end

    it "denies viewing another customer's order" do
      other_order = create(:order)

      get "/api/v1/customer/orders/#{other_order.id}", headers: headers

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /api/v1/customer/orders/:id/cancellation_request" do
    it "cancels immediately while still merchant_pending" do
      quote_id = build_quote
      post "/api/v1/customer/quotes/#{quote_id}/orders",
           params: { payment_method: "cash", idempotency_key: "order-3" }, headers: headers, as: :json
      order_id = response.parsed_body["id"]

      post "/api/v1/customer/orders/#{order_id}/cancellation_request", headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["current_status"]).to eq("cancelled")
    end
  end
end
