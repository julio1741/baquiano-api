require "rails_helper"

RSpec.describe "Admin roles, permissions and role assignments", type: :request do
  let(:permission) { create(:permission, resource: "users", action: "manage_roles") }
  let(:admin_role) { create(:role, code: "platform_admin") }
  let(:admin) { create(:user) }
  let(:plain_user) { create(:user) }

  before do
    create(:role_permission, role: admin_role, permission: permission)
    create(:role_assignment, user: admin, role: admin_role, assigned_by_user: admin)
  end

  describe "GET /api/v1/admin/roles" do
    it "denies a user with no role assignment" do
      get "/api/v1/admin/roles", headers: auth_headers_for(plain_user, app_type: "admin")

      expect(response).to have_http_status(:forbidden)
    end

    it "allows a user holding users:manage_roles" do
      get "/api/v1/admin/roles", headers: auth_headers_for(admin, app_type: "admin")

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.map { |r| r["code"] }).to include("platform_admin")
    end
  end

  describe "POST /api/v1/admin/roles" do
    it "creates a platform-scoped role" do
      post "/api/v1/admin/roles",
           params: { name: "Support Agent", code: "support_agent", scope_type: "platform" },
           headers: auth_headers_for(admin, app_type: "admin"), as: :json

      expect(response).to have_http_status(:created)
      expect(Role.find_by(code: "support_agent")).to be_present
    end

    it "rejects a role that names a non-existent organization" do
      post "/api/v1/admin/roles",
           params: { name: "Bad Role", code: "bad_role", scope_type: "organization", organization_id: SecureRandom.uuid },
           headers: auth_headers_for(admin, app_type: "admin"), as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["error"]["code"]).to eq("invalid_reference")
    end
  end

  describe "GET /api/v1/admin/permissions" do
    it "lists the permission catalog" do
      get "/api/v1/admin/permissions", headers: auth_headers_for(admin, app_type: "admin")

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.map { |p| p["code"] }).to include("users:manage_roles")
    end
  end

  describe "role assignments" do
    it "assigns and then revokes a role for a user" do
      target_role = create(:role, code: "support_agent")
      headers = auth_headers_for(admin, app_type: "admin")

      post "/api/v1/admin/role_assignments",
           params: { user_id: plain_user.id, role_id: target_role.id, starts_at: Time.current }, headers: headers, as: :json
      expect(response).to have_http_status(:created)
      assignment_id = response.parsed_body["id"]

      delete "/api/v1/admin/role_assignments/#{assignment_id}", headers: headers, as: :json
      expect(response).to have_http_status(:ok)
      expect(RoleAssignment.find(assignment_id).revoked_at).to be_present
    end

    it "denies assigning a role without users:manage_roles" do
      target_role = create(:role, code: "support_agent")

      post "/api/v1/admin/role_assignments",
           params: { user_id: plain_user.id, role_id: target_role.id, starts_at: Time.current },
           headers: auth_headers_for(plain_user, app_type: "admin"), as: :json

      expect(response).to have_http_status(:forbidden)
    end
  end
end
