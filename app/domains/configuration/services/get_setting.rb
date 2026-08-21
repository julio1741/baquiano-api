module Configuration
  class GetSetting
    def self.call(...) = new(...).call

    def initialize(scope_type:, key:, scope_id: nil)
      @scope_type = scope_type
      @scope_id = scope_id
      @key = key
    end

    def call
      setting = SystemSetting.where(scope_type: @scope_type, scope_id: @scope_id, key: @key)
        .where("effective_at <= ?", Time.current)
        .where("expires_at IS NULL OR expires_at > ?", Time.current)
        .order(version: :desc).first
      setting&.value
    end
  end
end
