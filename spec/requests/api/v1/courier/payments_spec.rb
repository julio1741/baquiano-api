require "rails_helper"

RSpec.describe "Courier payment collection", type: :request do
  it "collects a cash payment on delivery" do
    courier = create(:courier, cash_enabled: true, maximum_cash_exposure: 5_000)
    delivery = create(:delivery, courier: courier)
    delivery.order.update!(payment_method: "cash")
    Payments::CreatePaymentIntent.call(order: delivery.order)
    headers = auth_headers_for(courier.user, app_type: "courier")

    post "/api/v1/courier/deliveries/#{delivery.id}/collect_cash_payment", headers: headers

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body["payment_intent_status"]).to eq("captured")
  end

  it "denies collecting cash beyond the courier's exposure limit" do
    courier = create(:courier, cash_enabled: true, maximum_cash_exposure: 100)
    delivery = create(:delivery, courier: courier)
    delivery.order.update!(payment_method: "cash", total_amount: 1_000)
    Payments::CreatePaymentIntent.call(order: delivery.order)
    headers = auth_headers_for(courier.user, app_type: "courier")

    post "/api/v1/courier/deliveries/#{delivery.id}/collect_cash_payment", headers: headers

    expect(response).to have_http_status(:conflict)
    expect(response.parsed_body["error"]["code"]).to eq("cash_exposure_exceeded")
  end

  it "records a POS payment on delivery" do
    courier = create(:courier)
    delivery = create(:delivery, courier: courier)
    delivery.order.update!(payment_method: "pos_on_delivery")
    Payments::CreatePaymentIntent.call(order: delivery.order)
    headers = auth_headers_for(courier.user, app_type: "courier")

    post "/api/v1/courier/deliveries/#{delivery.id}/record_pos_payment", params: { receipt_reference: "RCP-1" },
                                                                          headers: headers, as: :json

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body["payment_intent_status"]).to eq("captured")
  end
end
