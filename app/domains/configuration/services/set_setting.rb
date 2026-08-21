module Configuration
  # Always inserts a new version — SystemSetting is append-only, so
  # "changing" a setting means writing version N+1, never editing version N.
  class SetSetting
    def self.call(...) = new(...).call

    def initialize(scope_type:, key:, value:, value_type:, updated_by:, scope_id: nil, encrypted: false,
                   expires_at: nil)
      @scope_type = scope_type
      @scope_id = scope_id
      @key = key
      @value = value
      @value_type = value_type
      @updated_by = updated_by
      @encrypted = encrypted
      @expires_at = expires_at
    end

    def call
      next_version = (current_version&.version || 0) + 1
      SystemSetting.create!(
        scope_type: @scope_type, scope_id: @scope_id, key: @key, value: @value, value_type: @value_type,
        encrypted: @encrypted, version: next_version, effective_at: Time.current, expires_at: @expires_at,
        updated_by_user: @updated_by
      )
    end

    private

    def current_version
      SystemSetting.where(scope_type: @scope_type, scope_id: @scope_id, key: @key).order(version: :desc).first
    end
  end
end
