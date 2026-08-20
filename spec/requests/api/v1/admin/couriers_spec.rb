require "rails_helper"

RSpec.describe "Admin courier management", type: :request do
  let(:permission) { create(:permission, resource: "organizations", action: "manage") }
  let(:admin_role) { create(:role, code: "platform_admin") }
  let(:admin) { create(:user) }
  let(:admin_headers) { auth_headers_for(admin, app_type: "admin") }

  before do
    create(:role_permission, role: admin_role, permission: permission)
    create(:role_assignment, user: admin, role: admin_role, assigned_by_user: admin)
  end

  it "approves a pending courier" do
    courier = create(:courier)
    expect(courier.approval_status).to eq("pending")

    post "/api/v1/admin/couriers/#{courier.id}/approve", headers: admin_headers

    expect(response.parsed_body["approval_status"]).to eq("approved")
    expect(response.parsed_body["status"]).to eq("active")
  end

  it "rejects a courier with a reason" do
    courier = create(:courier)

    post "/api/v1/admin/couriers/#{courier.id}/reject", params: { reason: "documento vencido" }, headers: admin_headers,
                                                          as: :json

    expect(response.parsed_body["approval_status"]).to eq("rejected")
  end

  it "denies a courier's own token from setting admin-only fields via the admin route" do
    courier_user = create(:user)
    courier = create(:courier, user: courier_user)
    courier_headers = auth_headers_for(courier_user, app_type: "courier")

    patch "/api/v1/admin/couriers/#{courier.id}", params: { cash_enabled: true }, headers: courier_headers, as: :json

    expect(response).to have_http_status(:forbidden)
    expect(courier.reload.cash_enabled).to be(false)
  end

  it "reviews a courier document" do
    document = create(:courier_document)

    post "/api/v1/admin/courier_documents/#{document.id}/approve", headers: admin_headers
    expect(response.parsed_body["status"]).to eq("approved")
  end

  it "force-assigns a courier to a delivery" do
    delivery = create(:delivery, status: "pending_assignment")
    courier = create(:courier)

    post "/api/v1/admin/deliveries/#{delivery.id}/assign", params: { courier_id: courier.id }, headers: admin_headers,
                                                            as: :json

    expect(response.parsed_body["status"]).to eq("assigned")
    expect(response.parsed_body["courier_id"]).to eq(courier.id)
  end
end
