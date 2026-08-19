require "rails_helper"

RSpec.describe Identity::PurgeExpiredOtpChallengesJob, type: :job do
  it "deletes challenges past the retention window and keeps everything else" do
    stale = create(:otp_challenge, expires_at: (described_class::RETENTION + 1.hour).ago)
    within_retention = create(:otp_challenge, expires_at: 1.hour.ago)
    still_valid = create(:otp_challenge, expires_at: 1.hour.from_now)

    described_class.perform_now

    expect(OtpChallenge.exists?(stale.id)).to be(false)
    expect(OtpChallenge.exists?(within_retention.id)).to be(true)
    expect(OtpChallenge.exists?(still_valid.id)).to be(true)
  end
end
