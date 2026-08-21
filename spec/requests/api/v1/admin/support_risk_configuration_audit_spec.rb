require "rails_helper"

RSpec.describe "Admin support, risk, configuration, audit, reports", type: :request do
  let(:permission) { create(:permission, resource: "organizations", action: "manage") }
  let(:admin_role) { create(:role, code: "platform_admin") }
  let(:admin) { create(:user) }
  let(:admin_headers) { auth_headers_for(admin, app_type: "admin") }

  before do
    create(:role_permission, role: admin_role, permission: permission)
    create(:role_assignment, user: admin, role: admin_role, assigned_by_user: admin)
  end

  describe "support cases" do
    it "lists, assigns, and transitions a case" do
      support_case = create(:support_case)

      get "/api/v1/admin/support_cases", headers: admin_headers
      expect(response.parsed_body.map { |c| c["id"] }).to include(support_case.id)

      post "/api/v1/admin/support_cases/#{support_case.id}/assign", params: { assigned_to_user_id: admin.id },
                                                                      headers: admin_headers, as: :json
      expect(response.parsed_body["assigned_to_user_id"]).to eq(admin.id)

      post "/api/v1/admin/support_cases/#{support_case.id}/transition", params: { status: "in_progress" },
                                                                          headers: admin_headers, as: :json
      expect(response.parsed_body["status"]).to eq("in_progress")
    end
  end

  describe "risk" do
    it "lists fraud signals and reviews a risk decision" do
      create(:fraud_signal)
      decision = create(:risk_decision)

      get "/api/v1/admin/fraud_signals", headers: admin_headers
      expect(response.parsed_body.size).to eq(1)

      post "/api/v1/admin/risk_decisions/#{decision.id}/review", headers: admin_headers
      expect(response.parsed_body["reviewed_by_user_id"]).to eq(admin.id)
    end

    it "denies access without risk:review or organizations:manage" do
      plain_user = create(:user)
      get "/api/v1/admin/fraud_signals", headers: auth_headers_for(plain_user, app_type: "admin")
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "configuration" do
    it "sets a versioned system setting and lists it" do
      post "/api/v1/admin/system_settings",
           params: { scope_type: "Platform", key: "delivery_search_radius_km", value: { km: 5 },
                     value_type: "json" },
           headers: admin_headers, as: :json
      expect(response).to have_http_status(:created)
      expect(response.parsed_body["version"]).to eq(1)

      get "/api/v1/admin/system_settings", headers: admin_headers
      expect(response.parsed_body.size).to eq(1)
    end

    it "creates and updates a feature flag" do
      post "/api/v1/admin/feature_flags", params: { key: "new_checkout_flow", enabled: false },
                                           headers: admin_headers, as: :json
      expect(response).to have_http_status(:created)
      flag_id = response.parsed_body["id"]

      patch "/api/v1/admin/feature_flags/#{flag_id}", params: { enabled: true }, headers: admin_headers, as: :json
      expect(response.parsed_body["enabled"]).to be true
    end
  end

  describe "audit log" do
    it "lists audit events with a truncation flag" do
      create(:audit_event)

      get "/api/v1/admin/audit_events", headers: admin_headers

      expect(response.parsed_body["events"].size).to eq(1)
      expect(response.parsed_body["truncated"]).to be false
    end
  end

  describe "reports" do
    it "returns basic orders-by-day operational metrics" do
      create(:order, current_status: "delivered", placed_at: Time.current, total_amount: 1_000)
      create(:order, current_status: "cancelled", placed_at: Time.current)

      get "/api/v1/admin/reports/orders_by_day", headers: admin_headers

      expect(response).to have_http_status(:ok)
      today = response.parsed_body.find { |row| row["date"] == Date.current.to_s }
      expect(today["orders"]).to eq(2)
      expect(today["cancelled_orders"]).to eq(1)
      expect(today["revenue_amount"]).to eq(1_000)
      expect(today["cancellation_rate"]).to eq(50.0)
    end
  end
end
