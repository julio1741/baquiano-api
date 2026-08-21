require "rails_helper"

RSpec.describe "Configuration and Idempotency", type: :model do
  it "SetSetting always creates a new version, GetSetting returns the latest" do
    admin = create(:user)
    Configuration::SetSetting.call(scope_type: "Platform", key: "delivery_search_radius_km", value: { "km" => 5 },
                                    value_type: "json", updated_by: admin)
    Configuration::SetSetting.call(scope_type: "Platform", key: "delivery_search_radius_km", value: { "km" => 8 },
                                    value_type: "json", updated_by: admin)

    expect(SystemSetting.where(key: "delivery_search_radius_km").count).to eq(2)
    expect(Configuration::GetSetting.call(scope_type: "Platform",
                                           key: "delivery_search_radius_km")).to eq({ "km" => 8 })
  end

  it "rejects a direct update on a SystemSetting (append-only)" do
    setting = create(:system_setting)
    expect { setting.update!(value: { "x" => 1 }) }.to raise_error(ActiveRecord::ReadOnlyRecord)
  end

  it "FeatureEnabled checks global enabled, then org-scoped rules" do
    admin = create(:user)
    flag = create(:feature_flag, enabled: false, rules: { "organization_ids" => [ "org-1" ] },
                                  created_by_user: admin, updated_by_user: admin)

    expect(Configuration::FeatureEnabled.call(key: flag.key)).to be false
    expect(Configuration::FeatureEnabled.call(key: flag.key, organization_id: "org-1")).to be true
    expect(Configuration::FeatureEnabled.call(key: flag.key, organization_id: "org-2")).to be false
  end

  it "Idempotency::Perform returns the same resource on replay and rejects a mismatched replay" do
    user = create(:user)
    resource = Idempotency::Perform.call(actor: user, operation: "test_op", key: "key-1", request_digest: "abc") do
      create(:support_case, opened_by_user: user)
    end

    replayed = Idempotency::Perform.call(actor: user, operation: "test_op", key: "key-1", request_digest: "abc") do
      raise "should not be called again"
    end
    expect(replayed).to eq(resource)

    expect {
      Idempotency::Perform.call(actor: user, operation: "test_op", key: "key-1", request_digest: "different") { nil }
    }.to raise_error(ConflictError)
  end
end
