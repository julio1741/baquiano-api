require "rails_helper"

RSpec.describe Pricing::PurgeExpiredQuotesJob, type: :job do
  it "deletes quotes past the retention window and keeps everything else" do
    stale = create(:quote, expires_at: (described_class::RETENTION + 1.hour).ago)
    within_retention = create(:quote, expires_at: 1.hour.ago)
    still_valid = create(:quote, expires_at: 1.hour.from_now)

    described_class.perform_now

    expect(Quote.exists?(stale.id)).to be(false)
    expect(Quote.exists?(within_retention.id)).to be(true)
    expect(Quote.exists?(still_valid.id)).to be(true)
  end
end
