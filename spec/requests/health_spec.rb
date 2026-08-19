require "rails_helper"

RSpec.describe "Health", type: :request do
  describe "GET /health/live" do
    it "returns ok without checking dependencies" do
      get "/health/live"

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq("status" => "ok")
    end
  end

  describe "GET /health/ready" do
    it "returns ok when the database and redis are reachable" do
      get "/health/ready"

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["checks"]).to eq("database" => true, "redis" => true)
    end

    it "returns 503 when a dependency is unreachable" do
      allow(Sidekiq).to receive(:redis).and_raise(Redis::CannotConnectError)

      get "/health/ready"

      expect(response).to have_http_status(:service_unavailable)
      expect(JSON.parse(response.body)["checks"]["redis"]).to be(false)
    end

    it "sets a correlation id header, generating one if the client sends none" do
      get "/health/ready"

      expect(response.headers["X-Correlation-Id"]).to be_present
    end

    it "echoes back a client-supplied correlation id" do
      get "/health/ready", headers: { "X-Correlation-ID" => "test-correlation-id" }

      expect(response.headers["X-Correlation-Id"]).to eq("test-correlation-id")
    end
  end
end
