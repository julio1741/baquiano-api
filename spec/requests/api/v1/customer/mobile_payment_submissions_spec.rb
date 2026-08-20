require "rails_helper"

RSpec.describe "Customer mobile payment submission", type: :request do
  it "submits a mobile payment for the customer's own order and moves it to pending_review" do
    order = create(:order, current_status: "payment_pending", payment_status: "pending", payment_method: "mobile_payment")
    Payments::CreatePaymentIntent.call(order: order)
    headers = auth_headers_for(order.customer.user, app_type: "customer")

    post "/api/v1/customer/orders/#{order.id}/mobile_payment_submissions",
         params: { reference: "REF-CUST-1", amount: order.total_amount, paid_at: Time.current.iso8601 },
         headers: headers, as: :json

    expect(response).to have_http_status(:created)
    expect(response.parsed_body["review_status"]).to eq("submitted")
    expect(order.payment_intent.reload.status).to eq("pending_review")
  end

  it "denies submitting a mobile payment for someone else's order" do
    order = create(:order, current_status: "payment_pending", payment_status: "pending", payment_method: "mobile_payment")
    Payments::CreatePaymentIntent.call(order: order)
    other_headers = auth_headers_for(create(:user), app_type: "customer")

    post "/api/v1/customer/orders/#{order.id}/mobile_payment_submissions",
         params: { reference: "REF-CUST-2", amount: order.total_amount, paid_at: Time.current.iso8601 },
         headers: other_headers, as: :json

    expect(response).to have_http_status(:not_found)
  end
end
