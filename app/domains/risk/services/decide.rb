module Risk
  class Decide
    def self.call(...) = new(...).call

    def initialize(subject:, decision:, risk_score:, reasons: {}, order: nil, rules_version: "v1")
      @subject = subject
      @decision = decision
      @risk_score = risk_score
      @reasons = reasons
      @order = order
      @rules_version = rules_version
    end

    def call
      RiskDecision.create!(
        subject: @subject, decision: @decision, risk_score: @risk_score, reasons: @reasons, order: @order,
        rules_version: @rules_version
      )
    end
  end
end
