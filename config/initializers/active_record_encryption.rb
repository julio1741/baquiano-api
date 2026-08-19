# Keys via ENV (like the rest of this app's config) instead of
# credentials.yml.enc, so they can be provisioned the same way as
# DATABASE_* / REDIS_URL across dev/CI/production without touching the
# shared master key. Generate a set with `bin/rails db:encryption:init`.
Rails.application.config.active_record.encryption.primary_key = ENV.fetch("AR_ENCRYPTION_PRIMARY_KEY")
Rails.application.config.active_record.encryption.deterministic_key = ENV.fetch("AR_ENCRYPTION_DETERMINISTIC_KEY")
Rails.application.config.active_record.encryption.key_derivation_salt = ENV.fetch("AR_ENCRYPTION_KEY_DERIVATION_SALT")
