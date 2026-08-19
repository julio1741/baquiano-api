require "rails_helper"

RSpec.describe Identity::CleanupSessionsJob, type: :job do
  it "deletes sessions revoked or expired past the retention window" do
    long_revoked = create(:session, revoked_at: (described_class::RETENTION + 1.day).ago)
    long_expired = create(:session, expires_at: (described_class::RETENTION + 1.day).ago)
    recently_revoked = create(:session, revoked_at: 1.day.ago)
    still_active = create(:session)

    described_class.perform_now

    expect(Session.exists?(long_revoked.id)).to be(false)
    expect(Session.exists?(long_expired.id)).to be(false)
    expect(Session.exists?(recently_revoked.id)).to be(true)
    expect(Session.exists?(still_active.id)).to be(true)
  end
end
