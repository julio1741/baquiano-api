require "rails_helper"

RSpec.describe Identity::VerifyOtp do
  let(:device_attrs) { { installation_id: "install-1", platform: "android", app_type: "customer" } }

  def create_challenge(phone: "4141234567", code: "123456")
    OtpChallenge.create!(
      phone_digest: BlindIndex.digest(Phone.e164("58", phone)),
      purpose: "sign_in",
      code_digest: BlindIndex.digest(code),
      expires_at: 5.minutes.from_now
    )
  end

  it "creates a new user on first verification" do
    create_challenge

    result = described_class.call(
      country_code: "58", phone_number: "4141234567", code: "123456", purpose: "sign_in",
      device_attrs: device_attrs, first_name: "Julio", last_name: "Baptista"
    )

    expect(result.user).to be_persisted
    expect(result.access_token).to be_present
    expect(result.refresh_token).to be_present
  end

  it "requires a name when signing up for the first time" do
    create_challenge

    expect do
      described_class.call(country_code: "58", phone_number: "4141234567", code: "123456", purpose: "sign_in",
                            device_attrs: device_attrs)
    end.to raise_error(ValidationError) { |e| expect(e.code).to eq("profile_required") }
  end

  it "rejects a disabled account" do
    create(:user, phone_country_code: "58", phone_number: "4141234567", disabled_at: Time.current)
    create_challenge

    expect do
      described_class.call(country_code: "58", phone_number: "4141234567", code: "123456", purpose: "sign_in",
                            device_attrs: device_attrs)
    end.to raise_error(ForbiddenError) { |e| expect(e.code).to eq("account_disabled") }
  end

  it "rejects a locked account" do
    create(:user, phone_country_code: "58", phone_number: "4141234567", locked_at: Time.current)
    create_challenge

    expect do
      described_class.call(country_code: "58", phone_number: "4141234567", code: "123456", purpose: "sign_in",
                            device_attrs: device_attrs)
    end.to raise_error(ForbiddenError) { |e| expect(e.code).to eq("account_locked") }
  end

  it "rejects a blocked device" do
    user = create(:user, phone_country_code: "58", phone_number: "4141234567")
    create(:device, user: user, installation_id: device_attrs[:installation_id], blocked_at: Time.current)
    create_challenge

    expect do
      described_class.call(country_code: "58", phone_number: "4141234567", code: "123456", purpose: "sign_in",
                            device_attrs: device_attrs)
    end.to raise_error(ForbiddenError) { |e| expect(e.code).to eq("device_blocked") }
  end

  it "does not consume the challenge or create a user when the device is blocked" do
    user = create(:user, phone_country_code: "58", phone_number: "4141234567")
    create(:device, user: user, installation_id: device_attrs[:installation_id], blocked_at: Time.current)
    challenge = create_challenge

    expect do
      begin
        described_class.call(country_code: "58", phone_number: "4141234567", code: "123456", purpose: "sign_in",
                              device_attrs: device_attrs)
      rescue ForbiddenError
        nil
      end
    end.not_to change(Session, :count)

    expect(challenge.reload.consumed?).to be(false)
  end
end
