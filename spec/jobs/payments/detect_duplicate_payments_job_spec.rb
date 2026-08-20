require "rails_helper"

RSpec.describe Payments::DetectDuplicatePaymentsJob, type: :job do
  it "flags a same-reference submission created concurrently (missed by the synchronous check) as duplicate" do
    pi1 = create(:payment_intent)
    pi2 = create(:payment_intent)
    original = create(:mobile_payment_submission, payment_intent: pi1, reference: "RACE-REF")
    racer = create(:mobile_payment_submission, payment_intent: pi2, reference: "RACE-REF")

    described_class.perform_now

    expect(racer.reload.review_status).to eq("duplicate")
    expect(racer.duplicate_of_submission).to eq(original)
    expect(original.reload.review_status).to eq("submitted")
  end

  it "never touches an already-decided submission" do
    pi1 = create(:payment_intent)
    pi2 = create(:payment_intent)
    create(:mobile_payment_submission, payment_intent: pi1, reference: "DECIDED-REF")
    confirmed = create(:mobile_payment_submission, payment_intent: pi2, reference: "DECIDED-REF",
                                                    review_status: "confirmed")

    described_class.perform_now

    expect(confirmed.reload.review_status).to eq("confirmed")
  end

  it "leaves unique references alone" do
    submission = create(:mobile_payment_submission, reference: "UNIQUE-REF")

    described_class.perform_now

    expect(submission.reload.review_status).to eq("submitted")
  end
end
