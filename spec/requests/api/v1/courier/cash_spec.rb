require "rails_helper"

RSpec.describe "Courier cash balance and handovers", type: :request do
  it "shows the courier's cash balance and initiates a handover" do
    courier = create(:courier, cash_enabled: true, maximum_cash_exposure: 5_000)
    delivery = create(:delivery, courier: courier)
    delivery.order.update!(payment_method: "cash")
    Payments::CreatePaymentIntent.call(order: delivery.order)
    headers = auth_headers_for(courier.user, app_type: "courier")

    post "/api/v1/courier/deliveries/#{delivery.id}/collect_cash_payment", headers: headers

    get "/api/v1/courier/cash_balances", headers: headers
    expect(response.parsed_body.first["amount_held"]).to eq(delivery.order.total_amount)

    supervisor = create(:user)
    post "/api/v1/courier/cash_handovers",
         params: { received_by_user_id: supervisor.id, amount: delivery.order.total_amount,
                   idempotency_key: "courier-handover-1" },
         headers: headers, as: :json

    expect(response).to have_http_status(:created)
    expect(response.parsed_body["status"]).to eq("pending")
  end

  it "lists the courier's own settlements" do
    courier = create(:courier)
    create(:settlement, beneficiary: courier)
    headers = auth_headers_for(courier.user, app_type: "courier")

    get "/api/v1/courier/settlements", headers: headers

    expect(response.parsed_body.size).to eq(1)
  end
end
