require "rails_helper"

RSpec.describe "Admin order visibility", type: :request do
  let(:permission) { create(:permission, resource: "organizations", action: "manage") }
  let(:admin_role) { create(:role, code: "platform_admin") }
  let(:admin) { create(:user) }
  let(:plain_user) { create(:user) }
  let(:admin_headers) { auth_headers_for(admin, app_type: "admin") }

  before do
    create(:role_permission, role: admin_role, permission: permission)
    create(:role_assignment, user: admin, role: admin_role, assigned_by_user: admin)
  end

  it "denies a user without organizations:manage" do
    get "/api/v1/admin/orders", headers: auth_headers_for(plain_user, app_type: "admin")

    expect(response).to have_http_status(:forbidden)
  end

  it "lists orders across every organization, optionally filtered by organization or status" do
    order_a = create(:order, current_status: "merchant_pending")
    order_b = create(:order, current_status: "delivered", organization: order_a.organization)
    create(:order, current_status: "merchant_pending")

    get "/api/v1/admin/orders", headers: admin_headers
    expect(response.parsed_body.map { |o| o["id"] }).to include(order_a.id, order_b.id)

    get "/api/v1/admin/orders", params: { organization_id: order_a.organization_id }, headers: admin_headers
    ids = response.parsed_body.map { |o| o["id"] }
    expect(ids).to contain_exactly(order_a.id, order_b.id)

    get "/api/v1/admin/orders", params: { status: "delivered" }, headers: admin_headers
    expect(response.parsed_body.map { |o| o["id"] }).to contain_exactly(order_b.id)
  end

  it "shows an order with its full status history" do
    order = create(:order, current_status: "merchant_pending")
    Orders::TransitionOrder.call(order: order, to_status: "merchant_accepted", actor_type: "system")

    get "/api/v1/admin/orders/#{order.id}", headers: admin_headers

    expect(response).to have_http_status(:ok)
    body = response.parsed_body
    expect(body["current_status"]).to eq("merchant_accepted")
    expect(body["status_history"].map { |h| h["to_status"] }).to eq(%w[merchant_accepted])
  end
end
