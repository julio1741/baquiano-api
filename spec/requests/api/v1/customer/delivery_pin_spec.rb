require "rails_helper"

RSpec.describe "Customer sees the delivery PIN once dispatch starts", type: :request do
  it "exposes the plaintext PIN on the order view once a delivery exists" do
    branch = create(:branch)
    order = create(:order, branch: branch, organization: branch.organization, merchant: branch.merchant,
                            current_status: "ready_for_pickup")
    delivery = Deliveries::CreateForOrder.call(order: order)

    customer_headers = auth_headers_for(order.customer.user, app_type: "customer")
    get "/api/v1/customer/orders/#{order.id}", headers: customer_headers

    expect(response.parsed_body["delivery_pin"]).to eq(delivery.delivery_pin)
    expect(response.parsed_body["delivery_pin"]).to match(/\A\d{4}\z/)
  end

  it "does not expose a PIN before a delivery exists" do
    order = create(:order, current_status: "preparing")
    customer_headers = auth_headers_for(order.customer.user, app_type: "customer")

    get "/api/v1/customer/orders/#{order.id}", headers: customer_headers

    expect(response.parsed_body["delivery_pin"]).to be_nil
  end
end
