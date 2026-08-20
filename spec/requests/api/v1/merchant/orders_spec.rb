require "rails_helper"

RSpec.describe "Merchant order handling", type: :request do
  let(:organization) { create(:organization) }
  let(:branch) { create(:branch, organization: organization) }
  let(:staff) { create(:user) }
  let(:permission) { create(:permission, resource: "orders", action: "update_status") }
  let(:role) { create(:role, :organization_scoped, code: "merchant_owner") }
  let(:staff_headers) { auth_headers_for(staff, app_type: "merchant") }

  before do
    create(:role_permission, role: role, permission: permission)
    create(:role_assignment, user: staff, role: role, assigned_by_user: staff, organization_id: organization.id)
  end


  it "lists only active orders for the branch" do
    active_order = create(:order, branch: branch, current_status: "merchant_pending")
    create(:order, branch: branch, current_status: "cancelled")
    other_branch_order = create(:order)

    get "/api/v1/merchant/branches/#{branch.id}/orders", headers: staff_headers

    ids = response.parsed_body.map { |o| o["id"] }
    expect(ids).to include(active_order.id)
    expect(ids).not_to include(other_branch_order.id)
    expect(ids.size).to eq(1)
  end

  it "walks an order through accept -> preparing -> ready_for_pickup" do
    order = create(:order, branch: branch, current_status: "merchant_pending")

    post "/api/v1/merchant/orders/#{order.id}/accept", headers: staff_headers
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body["current_status"]).to eq("merchant_accepted")

    post "/api/v1/merchant/orders/#{order.id}/start_preparing", headers: staff_headers
    expect(response.parsed_body["current_status"]).to eq("preparing")

    post "/api/v1/merchant/orders/#{order.id}/mark_ready", headers: staff_headers
    expect(response.parsed_body["current_status"]).to eq("ready_for_pickup")
  end

  it "rejects an order with a reason" do
    order = create(:order, branch: branch, current_status: "merchant_pending")

    post "/api/v1/merchant/orders/#{order.id}/reject", params: { reason_code: "out_of_stock" }, headers: staff_headers,
                                                        as: :json

    expect(response.parsed_body["current_status"]).to eq("merchant_rejected")
    expect(order.reload.cancellation_reason_code).to eq("out_of_stock")
  end

  it "requires a reason to reject" do
    order = create(:order, branch: branch, current_status: "merchant_pending")

    post "/api/v1/merchant/orders/#{order.id}/reject", headers: staff_headers

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body["error"]["code"]).to eq("reason_code_required")
  end

  it "denies staff without orders:update_status" do
    order = create(:order, branch: branch, current_status: "merchant_pending")
    outsider_headers = auth_headers_for(create(:user), app_type: "merchant")

    post "/api/v1/merchant/orders/#{order.id}/accept", headers: outsider_headers

    expect(response).to have_http_status(:forbidden)
  end
end
