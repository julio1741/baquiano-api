require "rails_helper"

RSpec.describe "Merchant branch, catalog and availability self-service", type: :request do
  let(:organization) { create(:organization) }
  let(:branch) { create(:branch, organization: organization) }
  let(:staff) { create(:user) }
  let(:outsider) { create(:user) }

  let(:branches_permission) { create(:permission, resource: "branches", action: "manage") }
  let(:catalog_permission) { create(:permission, resource: "catalog", action: "manage") }
  let(:availability_permission) { create(:permission, resource: "availability", action: "manage") }

  let(:merchant_role) do
    create(:role, :organization_scoped, code: "merchant_owner").tap do |role|
      create(:role_permission, role: role, permission: branches_permission)
      create(:role_permission, role: role, permission: catalog_permission)
      create(:role_permission, role: role, permission: availability_permission)
    end
  end
  let(:staff_headers) { auth_headers_for(staff, app_type: "merchant") }

  before do
    create(:role_assignment, user: staff, role: merchant_role, assigned_by_user: staff, organization_id: organization.id)
  end


  describe "branches" do
    it "lists only branches the staff member has access to" do
      branch # force creation before the request — it's a lazy `let`
      other_branch = create(:branch)

      get "/api/v1/merchant/branches", headers: staff_headers

      ids = response.parsed_body.map { |b| b["id"] }
      expect(ids).to include(branch.id)
      expect(ids).not_to include(other_branch.id)
    end

    it "denies an outsider" do
      get "/api/v1/merchant/branches/#{branch.id}", headers: auth_headers_for(outsider, app_type: "merchant")

      expect(response).to have_http_status(:forbidden)
    end

    it "pauses and resumes the branch" do
      post "/api/v1/merchant/branches/#{branch.id}/pause", params: { reason: "closed for the day" },
                                                             headers: staff_headers, as: :json
      expect(response.parsed_body["paused_at"]).to be_present

      post "/api/v1/merchant/branches/#{branch.id}/resume", headers: staff_headers, as: :json
      expect(response.parsed_body["paused_at"]).to be_nil
    end
  end

  describe "catalog management" do
    it "creates a catalog, category and product, then publishes" do
      post "/api/v1/merchant/branches/#{branch.id}/catalogs", params: { name: "Menu" }, headers: staff_headers,
                                                                as: :json
      expect(response).to have_http_status(:created)
      catalog_id = response.parsed_body["id"]
      expect(response.parsed_body["status"]).to eq("draft")

      post "/api/v1/merchant/catalogs/#{catalog_id}/categories", params: { name: "Bebidas" }, headers: staff_headers,
                                                                   as: :json
      expect(response).to have_http_status(:created)
      category_id = response.parsed_body["id"]

      post "/api/v1/merchant/catalogs/#{catalog_id}/products",
           params: { category_id: category_id, sku: "BEB-1", name: "Jugo", product_type: "simple",
                     base_price_amount: 500, currency: "VES" },
           headers: staff_headers, as: :json
      expect(response).to have_http_status(:created)

      post "/api/v1/merchant/catalogs/#{catalog_id}/publish", headers: staff_headers, as: :json
      expect(response.parsed_body["status"]).to eq("published")
    end

    it "refuses to publish an empty catalog" do
      catalog = create(:catalog, branch: branch)

      post "/api/v1/merchant/catalogs/#{catalog.id}/publish", headers: staff_headers, as: :json

      expect(response).to have_http_status(:conflict)
      expect(response.parsed_body["error"]["code"]).to eq("catalog_empty")
    end
  end

  describe "availability" do
    it "sets and updates a product's availability" do
      product = create(:product, catalog: create(:catalog, branch: branch))

      post "/api/v1/merchant/branches/#{branch.id}/inventory_items",
           params: { product_id: product.id, availability_status: "unavailable" }, headers: staff_headers, as: :json
      expect(response).to have_http_status(:created)
      item_id = response.parsed_body["id"]

      patch "/api/v1/merchant/inventory_items/#{item_id}", params: { availability_status: "available" },
                                                             headers: staff_headers, as: :json
      expect(response.parsed_body["availability_status"]).to eq("available")
    end
  end
end
