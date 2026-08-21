# Append-only, versioned per (scope_type, scope_id, key) — see
# Configuration::SystemSettings, the only place these should be written.
class SystemSetting < ApplicationRecord
  belongs_to :updated_by_user, class_name: "User"

  enum :value_type, { string: "string", integer: "integer", boolean: "boolean", json: "json" }, validate: true,
                     prefix: true

  validates :key, :value, :effective_at, presence: true
  validates :version, uniqueness: { scope: %i[scope_type scope_id key] }

  def readonly?
    persisted?
  end
end
