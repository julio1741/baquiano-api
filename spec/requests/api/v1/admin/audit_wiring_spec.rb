require "rails_helper"

RSpec.describe "Audit wiring into sensitive admin actions", type: :request do
  let(:permission) { create(:permission, resource: "organizations", action: "manage") }
  let(:admin_role) { create(:role, code: "platform_admin") }
  let(:admin) { create(:user) }
  let(:admin_headers) { auth_headers_for(admin, app_type: "admin") }

  before do
    create(:role_permission, role: admin_role, permission: permission)
    create(:role_assignment, user: admin, role: admin_role, assigned_by_user: admin)
  end

  it "records an audit event when a courier is approved" do
    courier = create(:courier)
    post "/api/v1/admin/couriers/#{courier.id}/approve", headers: admin_headers

    event = AuditEvent.find_by(action: "courier.approved", resource_id: courier.id)
    expect(event).to be_present
    expect(event.actor_user_id).to eq(admin.id)
  end

  it "records an audit event when a refund is approved" do
    order = create(:order, current_status: "delivered", payment_status: "confirmed", payment_method: "cash")
    create(:payment_intent, order: order, customer: order.customer, status: "captured", amount: order.total_amount)
    refund = Payments::RequestRefund.call(order: order, requested_by: create(:user), reason_code: "x", amount: 100,
                                           idempotency_key: "audit-refund-1")

    post "/api/v1/admin/refunds/#{refund.id}/approve", headers: admin_headers

    expect(AuditEvent.find_by(action: "refund.approved", resource_id: refund.id)).to be_present
  end
end
