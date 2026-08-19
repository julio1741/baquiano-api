require "rails_helper"

RSpec.describe User, type: :model do
  it "is valid with the factory defaults" do
    expect(build(:user)).to be_valid
  end

  it "requires first_name, last_name and a phone number" do
    user = build(:user, first_name: nil, last_name: nil, phone_number: nil)

    expect(user).not_to be_valid
    expect(user.errors.attribute_names).to include(:first_name, :last_name, :phone_number)
  end

  it "encrypts the phone number and email at rest" do
    user = create(:user, phone_number: "4141234567", email: "julio@example.com")

    raw = ActiveRecord::Base.connection.select_one(
      "SELECT phone_number_encrypted, email_encrypted FROM users WHERE id = '#{user.id}'"
    )

    expect(raw["phone_number_encrypted"]).not_to include("4141234567")
    expect(raw["email_encrypted"]).not_to include("julio@example.com")
  end

  it "computes the same phone digest regardless of formatting" do
    with_leading_zero = create(:user, phone_country_code: "58", phone_number: "04141234567")

    expect(described_class.find_by_phone("58", "4141234567")).to eq(with_leading_zero)
  end

  it "rejects a second user with the same phone number" do
    create(:user, phone_country_code: "58", phone_number: "4141234567")
    duplicate = build(:user, phone_country_code: "58", phone_number: "4141234567")

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:phone_number_digest]).to be_present
  end

  it "rejects a second user with the same email" do
    create(:user, email: "julio@example.com")
    duplicate = build(:user, email: "julio@example.com")

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:email_digest]).to be_present
  end

  it "allows any number of users without an email" do
    create(:user, email: nil)

    expect(build(:user, email: nil)).to be_valid
  end

  describe "#authenticatable?" do
    it "is false until the user is active and neither locked nor disabled" do
      pending_user = build(:user, status: :pending_verification)
      active_user = build(:user, :active)
      locked_user = build(:user, :active, locked_at: Time.current)

      expect(pending_user.authenticatable?).to be(false)
      expect(active_user.authenticatable?).to be(true)
      expect(locked_user.authenticatable?).to be(false)
    end
  end
end
