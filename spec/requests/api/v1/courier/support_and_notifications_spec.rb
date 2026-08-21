require "rails_helper"

RSpec.describe "Courier support cases and notifications", type: :request do
  it "opens a support case linked to the courier's own delivery" do
    courier = create(:courier)
    delivery = create(:delivery, courier: courier)
    headers = auth_headers_for(courier.user, app_type: "courier")

    post "/api/v1/courier/support_cases",
         params: { category: "delivery_issue", subject: "Cliente no aparece", description: "No responde",
                   delivery_id: delivery.id },
         headers: headers, as: :json

    expect(response).to have_http_status(:created)
    expect(SupportCase.find(response.parsed_body["id"]).delivery).to eq(delivery)
  end

  it "does not link a delivery that doesn't belong to the courier" do
    other_delivery = create(:delivery)
    courier = create(:courier)
    headers = auth_headers_for(courier.user, app_type: "courier")

    post "/api/v1/courier/support_cases",
         params: { category: "delivery_issue", subject: "x", description: "y", delivery_id: other_delivery.id },
         headers: headers, as: :json

    expect(response).to have_http_status(:created)
    expect(SupportCase.find(response.parsed_body["id"]).delivery).to be_nil
  end

  it "lists notifications and manages preferences" do
    courier = create(:courier)
    create(:notification, user: courier.user)
    headers = auth_headers_for(courier.user, app_type: "courier")

    get "/api/v1/courier/notifications", headers: headers
    expect(response.parsed_body.size).to eq(1)

    patch "/api/v1/courier/notification_preferences/courier_assigned", params: { sms_enabled: false },
                                                                         headers: headers, as: :json
    expect(response.parsed_body["sms_enabled"]).to be false
  end
end
