require "rails_helper"

RSpec.describe OtpChallenge, type: :model do
  describe "#matches_code?" do
    it "matches only the exact code the digest was generated from" do
      challenge = create(:otp_challenge, code_digest: BlindIndex.digest("123456"))

      expect(challenge.matches_code?("123456")).to be(true)
      expect(challenge.matches_code?("654321")).to be(false)
    end
  end

  describe "#usable?" do
    it "is false once consumed" do
      challenge = create(:otp_challenge)
      challenge.consume!

      expect(challenge.usable?).to be(false)
    end

    it "is false once expired" do
      challenge = create(:otp_challenge, expires_at: 1.minute.ago)

      expect(challenge.usable?).to be(false)
    end

    it "is false once attempts are exhausted" do
      challenge = create(:otp_challenge, maximum_attempts: 2, attempt_count: 2)

      expect(challenge.usable?).to be(false)
    end

    it "is true otherwise" do
      expect(create(:otp_challenge).usable?).to be(true)
    end
  end

  describe "#register_attempt!" do
    it "increments attempt_count" do
      challenge = create(:otp_challenge)

      expect { challenge.register_attempt! }.to change { challenge.attempt_count }.by(1)
    end
  end
end
