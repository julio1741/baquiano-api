require "rails_helper"

RSpec.describe "Courier profile and delivery execution", type: :request do
  let(:user) { create(:user) }
  let(:headers) { auth_headers_for(user, app_type: "courier") }

  it "completes a profile, registers a vehicle and a document" do
    post "/api/v1/courier/profile", params: { courier_type: "baquiano", risk_level: "standard" }, headers: headers,
                                     as: :json
    expect(response).to have_http_status(:created)
    expect(response.parsed_body["approval_status"]).to eq("pending")

    post "/api/v1/courier/vehicles",
         params: { vehicle_type: "motorcycle", brand: "Yamaha", model: "YBR125", plate: "ABC123" },
         headers: headers, as: :json
    expect(response).to have_http_status(:created)

    post "/api/v1/courier/courier_documents",
         params: { document_type: "national_id", attachment_reference: "s3://doc.jpg", document_number: "V-123" },
         headers: headers, as: :json
    expect(response).to have_http_status(:created)
    expect(response.parsed_body["status"]).to eq("pending")
  end

  it "changes availability, going online then offline" do
    create(:courier, user: user)

    post "/api/v1/courier/availabilities", params: { status: "online" }, headers: headers, as: :json
    expect(response.parsed_body["status"]).to eq("online")

    post "/api/v1/courier/availabilities", params: { status: "offline" }, headers: headers, as: :json
    expect(response.parsed_body["status"]).to eq("offline")
  end

  it "records a location ping" do
    create(:courier, user: user)

    post "/api/v1/courier/location_pings",
         params: { latitude: 8.62, longitude: -70.21, source: "gps" }, headers: headers, as: :json
    expect(response).to have_http_status(:created)
  end

  describe "dispatch offers and full delivery execution" do
    it "lets the courier accept an offer and execute the delivery through to PIN-confirmed delivery" do
      courier = create(:courier, user: user, status: "active", approval_status: "approved")
      branch = create(:branch)
      order = create(:order, branch: branch, organization: branch.organization, merchant: branch.merchant,
                              current_status: "courier_search")
      delivery = create(:delivery, order: order, branch: branch, status: "offered",
                                    delivery_pin_digest: BlindIndex.digest("4821"))
      offer = create(:dispatch_offer, delivery: delivery, courier: courier)
      create(:dispatch_offer, delivery: delivery, courier: create(:courier)) # a losing competitor

      get "/api/v1/courier/dispatch_offers", headers: headers
      expect(response.parsed_body.map { |o| o["id"] }).to contain_exactly(offer.id)

      post "/api/v1/courier/dispatch_offers/#{offer.id}/accept", headers: headers
      expect(response.parsed_body["status"]).to eq("accepted")
      expect(order.reload.current_status).to eq("courier_assigned")

      post "/api/v1/courier/deliveries/#{delivery.id}/arrive_at_merchant", headers: headers
      expect(response.parsed_body["status"]).to eq("at_merchant")

      post "/api/v1/courier/deliveries/#{delivery.id}/confirm_pickup", headers: headers
      expect(response.parsed_body["status"]).to eq("en_route")
      expect(order.reload.current_status).to eq("en_route")

      post "/api/v1/courier/deliveries/#{delivery.id}/arrive_at_customer", headers: headers
      expect(response.parsed_body["status"]).to eq("at_customer")

      post "/api/v1/courier/deliveries/#{delivery.id}/confirm_delivery", params: { pin: "0000" }, headers: headers,
                                                                          as: :json
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["error"]["code"]).to eq("delivery_pin_mismatch")

      post "/api/v1/courier/deliveries/#{delivery.id}/confirm_delivery", params: { pin: "4821" }, headers: headers,
                                                                          as: :json
      expect(response.parsed_body["status"]).to eq("delivered")
      expect(order.reload.current_status).to eq("delivered")
    end

    it "rejects an offer that doesn't belong to this courier" do
      other_offer = create(:dispatch_offer)
      create(:courier, user: user)

      post "/api/v1/courier/dispatch_offers/#{other_offer.id}/accept", headers: headers
      expect(response).to have_http_status(:not_found)
    end
  end

  it "lets the courier report a delivery incident" do
    courier = create(:courier, user: user)
    delivery = create(:delivery, status: "at_merchant", courier: courier)

    post "/api/v1/courier/deliveries/#{delivery.id}/delivery_incidents",
         params: { incident_type: "customer_unreachable", description: "No contesta" }, headers: headers, as: :json

    expect(response).to have_http_status(:created)
    expect(DeliveryIncident.count).to eq(1)
  end
end
