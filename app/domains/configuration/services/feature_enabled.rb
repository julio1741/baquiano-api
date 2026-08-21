module Configuration
  # rules supports one simple targeting shape for now:
  # {"organization_ids" => [...]} — a flag can be globally enabled, or
  # scoped to specific organizations regardless of the global switch. No
  # percentage rollout / gradual release logic exists yet.
  class FeatureEnabled
    def self.call(...) = new(...).call

    def initialize(key:, organization_id: nil)
      @key = key
      @organization_id = organization_id
    end

    def call
      flag = FeatureFlag.find_by(key: @key)
      return false unless flag

      return true if flag.enabled
      return false if @organization_id.nil?

      Array(flag.rules["organization_ids"]).include?(@organization_id)
    end
  end
end
