require "rails_helper"

RSpec.describe "Admin organizations, merchants and branches", type: :request do
  let(:permission) { create(:permission, resource: "organizations", action: "manage") }
  let(:admin_role) { create(:role, code: "platform_admin") }
  let(:admin) { create(:user) }
  let(:plain_user) { create(:user) }
  let(:admin_headers) { auth_headers_for(admin, app_type: "admin") }

  before do
    create(:role_permission, role: admin_role, permission: permission)
    create(:role_assignment, user: admin, role: admin_role, assigned_by_user: admin)
  end


  describe "organizations" do
    it "denies a user without organizations:manage" do
      get "/api/v1/admin/organizations", headers: auth_headers_for(plain_user, app_type: "admin")

      expect(response).to have_http_status(:forbidden)
    end

    it "creates, reads, updates an organization" do
      post "/api/v1/admin/organizations",
           params: { legal_name: "Comercios Barinas C.A.", display_name: "Comercios Barinas",
                     organization_type: "merchant", default_currency: "VES", tax_identifier: "J-12345678-9" },
           headers: admin_headers, as: :json
      expect(response).to have_http_status(:created)
      org_id = response.parsed_body["id"]

      get "/api/v1/admin/organizations/#{org_id}", headers: admin_headers
      expect(response.parsed_body["legal_name"]).to eq("Comercios Barinas C.A.")

      patch "/api/v1/admin/organizations/#{org_id}", params: { display_name: "Nuevo Nombre" }, headers: admin_headers,
                                                       as: :json
      expect(response.parsed_body["display_name"]).to eq("Nuevo Nombre")
    end
  end

  describe "merchants" do
    it "creates a merchant under an organization" do
      organization = create(:organization)

      post "/api/v1/admin/merchants",
           params: { organization_id: organization.id, slug: "restaurante-x", vertical: "restaurant" },
           headers: admin_headers, as: :json

      expect(response).to have_http_status(:created)
      expect(Merchant.find_by(slug: "restaurante-x").organization).to eq(organization)
    end
  end

  describe "branches" do
    it "creates a branch, rejecting a merchant from a different organization" do
      organization = create(:organization)
      other_organization_merchant = create(:merchant)

      post "/api/v1/admin/branches",
           params: {
             organization_id: organization.id, merchant_id: other_organization_merchant.id,
             name: "Sucursal Centro", slug: "centro", delivery_model: "hybrid", address_text: "Av Bolivar",
             latitude: 8.62, longitude: -70.21
           }, headers: admin_headers, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["error"]["code"]).to eq("merchant_organization_mismatch")
    end

    it "creates, pauses and resumes a branch" do
      organization = create(:organization)
      merchant = create(:merchant, organization: organization)

      post "/api/v1/admin/branches",
           params: {
             organization_id: organization.id, merchant_id: merchant.id,
             name: "Sucursal Centro", slug: "centro", delivery_model: "hybrid", address_text: "Av Bolivar",
             latitude: 8.62, longitude: -70.21
           }, headers: admin_headers, as: :json
      expect(response).to have_http_status(:created)
      body = response.parsed_body
      expect(body["latitude"]).to be_within(0.001).of(8.62)
      expect(body["longitude"]).to be_within(0.001).of(-70.21)
      branch_id = body["id"]

      post "/api/v1/admin/branches/#{branch_id}/pause", params: { reason: "remodeling" }, headers: admin_headers,
                                                          as: :json
      expect(response.parsed_body["paused_at"]).to be_present

      post "/api/v1/admin/branches/#{branch_id}/resume", headers: admin_headers, as: :json
      expect(response.parsed_body["paused_at"]).to be_nil
    end
  end
end
