module Risk
  # Section 16 rules out an automated ML risk engine for the MVP, but a
  # signal severe enough to matter still needs to actually reach a human —
  # RiskDecision has no other creation path (Risk::Decide has no other
  # caller, and there's no admin "create decision" endpoint), so without
  # this a high/critical signal would sit in fraud_signals forever with
  # nothing surfacing it for Admin::RiskDecisionsController#review. Found
  # via live E2E: the impossible-speed signal fired correctly but
  # risk_decisions stayed empty.
  AUTO_REVIEW_SEVERITIES = %w[high critical].freeze

  class RecordSignal
    def self.call(...) = new(...).call

    def initialize(subject:, signal_type:, score:, severity:, order: nil, payment_intent: nil, evidence: {})
      @subject = subject
      @signal_type = signal_type
      @score = score
      @severity = severity
      @order = order
      @payment_intent = payment_intent
      @evidence = evidence
    end

    def call
      signal = FraudSignal.create!(
        subject: @subject, signal_type: @signal_type, score: @score, severity: @severity, order: @order,
        payment_intent: @payment_intent, evidence: @evidence, detected_at: Time.current
      )
      open_review_decision(signal) if AUTO_REVIEW_SEVERITIES.include?(@severity)
      signal
    end

    private

    def open_review_decision(signal)
      Risk::Decide.call(
        subject: @subject, decision: "manual_review", risk_score: @score, order: @order,
        reasons: { signal_type: @signal_type, fraud_signal_id: signal.id }
      )
    end
  end
end
