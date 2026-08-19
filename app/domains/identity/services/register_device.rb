module Identity
  # Idempotent upsert: the same installation calling this twice (e.g. app
  # reinstall keeps the installation_id, or a token refresh) updates the
  # existing device row instead of creating a duplicate.
  class RegisterDevice
    def self.call(...) = new(...).call

    def initialize(user:, installation_id:, platform:, app_type:, app_version: nil, os_version: nil,
                   device_model: nil, push_token: nil, push_provider: nil, fingerprint: nil)
      @user = user
      @installation_id = installation_id
      @platform = platform
      @app_type = app_type
      @app_version = app_version
      @os_version = os_version
      @device_model = device_model
      @push_token = push_token
      @push_provider = push_provider
      @fingerprint = fingerprint
    end

    def call
      device = Device.find_or_initialize_by(user: @user, installation_id: @installation_id)
      device.assign_attributes(
        platform: @platform,
        app_type: @app_type,
        app_version: @app_version,
        os_version: @os_version,
        device_model: @device_model,
        push_provider: @push_provider,
        last_seen_at: Time.current
      )
      device.device_fingerprint_digest = BlindIndex.digest(@fingerprint) if @fingerprint.present?
      device.push_token_encrypted = @push_token if @push_token.present?
      device.save!
      device
    end
  end
end
