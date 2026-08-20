require "rails_helper"

RSpec.describe "Customer refund request", type: :request do
  it "requests a refund for the customer's own delivered order" do
    order = create(:order, current_status: "delivered", payment_status: "confirmed", payment_method: "cash")
    create(:payment_intent, order: order, customer: order.customer, status: "captured", amount: order.total_amount)
    headers = auth_headers_for(order.customer.user, app_type: "customer")

    post "/api/v1/customer/orders/#{order.id}/refunds",
         params: { reason_code: "wrong_item", amount: 200, idempotency_key: "cust-refund-1" },
         headers: headers, as: :json

    expect(response).to have_http_status(:created)
    expect(response.parsed_body["status"]).to eq("requested")
    expect(order.reload.current_status).to eq("refund_pending")
  end

  it "denies requesting a refund for someone else's order" do
    order = create(:order, current_status: "delivered", payment_status: "confirmed", payment_method: "cash")
    create(:payment_intent, order: order, customer: order.customer, status: "captured", amount: order.total_amount)
    other_headers = auth_headers_for(create(:user), app_type: "customer")

    post "/api/v1/customer/orders/#{order.id}/refunds",
         params: { reason_code: "wrong_item", amount: 200, idempotency_key: "cust-refund-2" },
         headers: other_headers, as: :json

    expect(response).to have_http_status(:not_found)
  end
end
