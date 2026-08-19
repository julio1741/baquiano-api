require "rails_helper"

RSpec.describe "Customer addresses, cart and quote", type: :request do
  let(:city) { create(:city) }
  let(:organization) { create(:organization) }
  let(:branch) { create(:branch, organization: organization) }
  let(:catalog) { create(:catalog, branch: branch) }
  let(:category) { create(:category, catalog: catalog) }
  let(:product) { create(:product, catalog: catalog, category: category, base_price_amount: 1_000, currency: "VES") }
  let(:customer_user) { create(:user) }
  let(:headers) { auth_headers_for(customer_user, app_type: "customer") }

  before { Customers::EnsureProfile.call(user: customer_user) }

  describe "addresses" do
    it "creates, lists, updates and archives an address, enforcing a single default" do
      post "/api/v1/customer/addresses",
           params: { recipient_name: "Julio", original_text: "Av Bolivar", city_id: city.id,
                     latitude: 8.61, longitude: -70.21, is_default: true },
           headers: headers, as: :json
      expect(response).to have_http_status(:created)
      first_id = response.parsed_body["id"]
      expect(response.parsed_body["is_default"]).to be(true)

      post "/api/v1/customer/addresses",
           params: { recipient_name: "Julio", original_text: "Otra direccion", city_id: city.id,
                     latitude: 8.62, longitude: -70.22, is_default: true },
           headers: headers, as: :json
      expect(response).to have_http_status(:created)

      get "/api/v1/customer/addresses", headers: headers
      bodies = response.parsed_body
      expect(bodies.find { |a| a["id"] == first_id }["is_default"]).to be(false)

      delete "/api/v1/customer/addresses/#{first_id}", headers: headers
      expect(response).to have_http_status(:no_content)

      get "/api/v1/customer/addresses", headers: headers
      expect(response.parsed_body.map { |a| a["id"] }).not_to include(first_id)
    end

    it "denies access to another customer's address" do
      other_address = create(:address)

      patch "/api/v1/customer/addresses/#{other_address.id}", params: { label: "hacked" }, headers: headers, as: :json

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "cart and quote lifecycle" do
    it "gets or creates a cart, adds/updates/removes items, and generates a quote" do
      post "/api/v1/customer/branches/#{branch.id}/cart", headers: headers
      expect(response).to have_http_status(:ok)
      cart_id = response.parsed_body["id"]

      post "/api/v1/customer/branches/#{branch.id}/cart", headers: headers
      expect(response.parsed_body["id"]).to eq(cart_id)

      post "/api/v1/customer/carts/#{cart_id}/items", params: { product_id: product.id, quantity: 2 },
                                                       headers: headers, as: :json
      expect(response).to have_http_status(:created)
      item_id = response.parsed_body["id"]
      expect(response.parsed_body["line_total"]).to eq(2_000)

      patch "/api/v1/customer/cart_items/#{item_id}", params: { quantity: 3 }, headers: headers, as: :json
      expect(response.parsed_body["quantity"]).to eq(3)

      get "/api/v1/customer/carts/#{cart_id}", headers: headers
      expect(response.parsed_body["items"].size).to eq(1)

      address = create(:address, customer: customer_user.customer, city: city)
      create(:delivery_fee_rule, city: city, calculation_type: "fixed", base_amount: 150, currency: "VES")

      post "/api/v1/customer/carts/#{cart_id}/quotes",
           params: { address_id: address.id, idempotency_key: "quote-1" }, headers: headers, as: :json
      expect(response).to have_http_status(:created)
      body = response.parsed_body
      expect(body["subtotal_amount"]).to eq(3_000)
      expect(body["delivery_fee_amount"]).to eq(150)
      expect(body["total_amount"]).to eq(3_150)
      quote_id = body["id"]

      post "/api/v1/customer/carts/#{cart_id}/quotes",
           params: { address_id: address.id, idempotency_key: "quote-1" }, headers: headers, as: :json
      expect(response.parsed_body["id"]).to eq(quote_id)

      delete "/api/v1/customer/cart_items/#{item_id}", headers: headers
      expect(response).to have_http_status(:no_content)
    end

    it "refuses a quote for an empty cart" do
      post "/api/v1/customer/branches/#{branch.id}/cart", headers: headers
      cart_id = response.parsed_body["id"]
      address = create(:address, customer: customer_user.customer, city: city)

      post "/api/v1/customer/carts/#{cart_id}/quotes",
           params: { address_id: address.id, idempotency_key: "empty-cart" }, headers: headers, as: :json

      expect(response).to have_http_status(:conflict)
      expect(response.parsed_body["error"]["code"]).to eq("cart_empty")
    end

    it "denies acting on another customer's cart" do
      other_cart = create(:cart)

      get "/api/v1/customer/carts/#{other_cart.id}", headers: headers

      expect(response).to have_http_status(:forbidden)
    end
  end
end
