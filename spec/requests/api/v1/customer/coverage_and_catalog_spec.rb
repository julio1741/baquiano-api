require "rails_helper"

RSpec.describe "Customer coverage and catalog browsing (unauthenticated)", type: :request do
  let(:rgeo_factory) { RGeo::Geographic.spherical_factory(srid: 4326) }
  let(:city) { create(:city) }
  let(:branch) { create(:branch, status: "active") }

  def covering_geometry
    ring = rgeo_factory.linear_ring([
      rgeo_factory.point(-70.30, 8.60), rgeo_factory.point(-70.10, 8.60),
      rgeo_factory.point(-70.10, 8.70), rgeo_factory.point(-70.30, 8.70), rgeo_factory.point(-70.30, 8.60)
    ])
    rgeo_factory.multi_polygon([ rgeo_factory.polygon(ring) ])
  end

  describe "GET /api/v1/customer/coverage" do
    it "lists branches whose service area covers the given point, without requiring auth" do
      create(:service_area, branch: branch, city: city, geometry: covering_geometry)

      get "/api/v1/customer/coverage", params: { latitude: 8.65, longitude: -70.20 }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.map { |b| b["id"] }).to eq([ branch.id ])
    end

    it "excludes a paused branch even if its area covers the point" do
      create(:service_area, branch: branch, city: city, geometry: covering_geometry)
      branch.pause!

      get "/api/v1/customer/coverage", params: { latitude: 8.65, longitude: -70.20 }

      expect(response.parsed_body).to be_empty
    end

    it "returns an empty list outside any covered area" do
      create(:service_area, branch: branch, city: city, geometry: covering_geometry)

      get "/api/v1/customer/coverage", params: { latitude: 0.0, longitude: 0.0 }

      expect(response.parsed_body).to be_empty
    end
  end

  describe "GET /api/v1/customer/branches/:branch_id/catalog" do
    it "shows only the published catalog with active categories and products" do
      catalog = create(:catalog, branch: branch, status: "published", published_at: Time.current)
      visible_category = create(:category, catalog: catalog, name: "Visible")
      create(:product, catalog: catalog, category: visible_category, name: "Visible product")
      create(:product, catalog: catalog, category: visible_category, name: "Hidden product", active: false)
      create(:category, catalog: catalog, name: "Hidden category", active: false)

      get "/api/v1/customer/branches/#{branch.id}/catalog"

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["categories"].map { |c| c["name"] }).to eq([ "Visible" ])
      expect(body["categories"].first["products"].map { |p| p["name"] }).to eq([ "Visible product" ])
    end

    it "404s when the branch has no published catalog" do
      create(:catalog, branch: branch, status: "draft")

      get "/api/v1/customer/branches/#{branch.id}/catalog"

      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body["error"]["code"]).to eq("catalog_not_found")
    end
  end
end
