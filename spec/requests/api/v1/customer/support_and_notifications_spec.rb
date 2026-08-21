require "rails_helper"

RSpec.describe "Customer support cases and notifications", type: :request do
  it "opens a support case linked to the customer's own order" do
    order = create(:order)
    headers = auth_headers_for(order.customer.user, app_type: "customer")

    post "/api/v1/customer/support_cases",
         params: { category: "order_issue", subject: "No llegó", description: "El pedido no llegó",
                   order_id: order.id },
         headers: headers, as: :json

    expect(response).to have_http_status(:created)
    body = response.parsed_body
    expect(body["status"]).to eq("open")
    expect(SupportCase.find(body["id"]).order).to eq(order)
    expect(SupportCase.find(body["id"]).customer).to eq(order.customer)
  end

  it "does not link an order that doesn't belong to the customer" do
    other_order = create(:order)
    unrelated_customer = create(:customer)
    headers = auth_headers_for(unrelated_customer.user, app_type: "customer")

    post "/api/v1/customer/support_cases",
         params: { category: "order_issue", subject: "x", description: "y", order_id: other_order.id },
         headers: headers, as: :json

    expect(response).to have_http_status(:created)
    expect(SupportCase.find(response.parsed_body["id"]).order).to be_nil
  end

  it "lists only the current user's own support cases" do
    user = create(:user)
    mine = create(:support_case, opened_by_user: user)
    create(:support_case)
    headers = auth_headers_for(user, app_type: "customer")

    get "/api/v1/customer/support_cases", headers: headers

    expect(response.parsed_body.map { |c| c["id"] }).to eq([ mine.id ])
  end

  it "lists notifications and lets the customer manage their own preferences" do
    user = create(:user)
    create(:notification, user: user)
    headers = auth_headers_for(user, app_type: "customer")

    get "/api/v1/customer/notifications", headers: headers
    expect(response.parsed_body.size).to eq(1)

    patch "/api/v1/customer/notification_preferences/order_accepted", params: { push_enabled: false },
                                                                        headers: headers, as: :json
    expect(response.parsed_body["push_enabled"]).to be false

    get "/api/v1/customer/notification_preferences", headers: headers
    expect(response.parsed_body.first["notification_type"]).to eq("order_accepted")
  end
end
