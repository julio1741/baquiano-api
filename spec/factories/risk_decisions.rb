FactoryBot.define do
  factory :risk_decision do
    subject factory: :customer
    decision { "allow" }
    risk_score { 10.0 }
    rules_version { "v1" }
  end
end
