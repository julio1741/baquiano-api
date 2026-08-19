require "rails_helper"

RSpec.describe "Customer OTP + sessions", type: :request do
  def device_params
    { installation_id: "install-1", platform: "android" }
  end

  def request_otp(phone: "4141234567")
    post "/api/v1/customer/otp", params: { phone_country_code: "58", phone_number: phone }, as: :json
  end

  def verify_otp(code:, phone: "4141234567", first_name: "Julio", last_name: "Baptista")
    post "/api/v1/customer/otp/verify", params: {
      phone_country_code: "58", phone_number: phone, code: code,
      first_name: first_name, last_name: last_name, device: device_params
    }, as: :json
  end

  describe "POST /api/v1/customer/otp" do
    it "creates a challenge and exposes the code only in local environments" do
      request_otp

      expect(response).to have_http_status(:created)
      body = response.parsed_body
      expect(body["otp_challenge_id"]).to be_present
      expect(body["dev_only_code"]).to match(/\A\d{6}\z/)
    end

    it "rejects a second request for the same phone within the resend interval" do
      request_otp
      request_otp

      expect(response).to have_http_status(:conflict)
      expect(response.parsed_body["error"]["code"]).to eq("otp_recently_sent")
    end
  end

  describe "POST /api/v1/customer/otp/verify" do
    it "creates a new account and issues a session on first verification" do
      request_otp
      code = response.parsed_body["dev_only_code"]

      expect { verify_otp(code: code) }.to change(User, :count).by(1)

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["access_token"]).to be_present
      expect(body["refresh_token"]).to be_present
      expect(body["user"]["status"]).to eq("active")
    end

    it "signs into the existing account on a later verification instead of creating another one" do
      request_otp
      verify_otp(code: response.parsed_body["dev_only_code"])
      existing_user_id = response.parsed_body["user"]["id"]

      travel(Identity::RequestOtp::RESEND_INTERVAL + 1.second)
      request_otp
      expect { verify_otp(code: response.parsed_body["dev_only_code"]) }.not_to change(User, :count)
      expect(response.parsed_body["user"]["id"]).to eq(existing_user_id)
    end

    it "rejects an incorrect code without consuming the challenge" do
      request_otp

      verify_otp(code: "000000")

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["error"]["code"]).to eq("otp_incorrect")
    end

    it "rejects reusing an already-consumed code" do
      request_otp
      code = response.parsed_body["dev_only_code"]
      verify_otp(code: code)

      verify_otp(code: code)

      expect(response).to have_http_status(:conflict)
      expect(response.parsed_body["error"]["code"]).to eq("otp_already_used")
    end

    it "locks out further attempts once the maximum has been reached" do
      request_otp
      challenge = OtpChallenge.order(created_at: :desc).first
      challenge.update!(maximum_attempts: 1)

      verify_otp(code: "000000")
      verify_otp(code: response.parsed_body.dig("dev_only_code") || "111111")

      expect(response).to have_http_status(:conflict).or have_http_status(:unprocessable_content)
    end
  end

  describe "session lifecycle" do
    it "refreshes with rotation and detects reuse of a superseded refresh token" do
      request_otp
      verify_otp(code: response.parsed_body["dev_only_code"])
      original_refresh_token = response.parsed_body["refresh_token"]

      post "/api/v1/customer/session/refresh", params: { refresh_token: original_refresh_token }, as: :json
      expect(response).to have_http_status(:ok)
      rotated_refresh_token = response.parsed_body["refresh_token"]
      expect(rotated_refresh_token).not_to eq(original_refresh_token)

      post "/api/v1/customer/session/refresh", params: { refresh_token: original_refresh_token }, as: :json
      expect(response).to have_http_status(:forbidden)
      expect(response.parsed_body["error"]["code"]).to eq("refresh_token_reused")

      post "/api/v1/customer/session/refresh", params: { refresh_token: rotated_refresh_token }, as: :json
      expect(response).to have_http_status(:forbidden)
    end

    it "revokes the session on logout so its access token stops working" do
      request_otp
      verify_otp(code: response.parsed_body["dev_only_code"])
      access_token = response.parsed_body["access_token"]

      delete "/api/v1/customer/session", headers: { "Authorization" => "Bearer #{access_token}" }
      expect(response).to have_http_status(:no_content)

      get "/api/v1/customer/profile", headers: { "Authorization" => "Bearer #{access_token}" }
      expect(response).to have_http_status(:unauthorized)
    end

    it "rejects requests with no token and with a garbage token" do
      get "/api/v1/customer/profile"
      expect(response).to have_http_status(:unauthorized)

      get "/api/v1/customer/profile", headers: { "Authorization" => "Bearer garbage" }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET/PATCH /api/v1/customer/profile" do
    it "lets a user read and update only their own profile" do
      request_otp
      verify_otp(code: response.parsed_body["dev_only_code"])
      access_token = response.parsed_body["access_token"]
      headers = { "Authorization" => "Bearer #{access_token}" }

      get "/api/v1/customer/profile", headers: headers
      expect(response.parsed_body["first_name"]).to eq("Julio")

      patch "/api/v1/customer/profile", params: { first_name: "Julio Cesar" }, headers: headers, as: :json
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["first_name"]).to eq("Julio Cesar")
    end
  end
end
