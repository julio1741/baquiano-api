# Idempotent: safe to run in every environment and at any point.

# Reference permission catalog (section 4.2 of the spec). Codes for domains
# that don't have models/enforcement yet (orders, deliveries, payments,
# ledger) are seeded anyway so later increments' policies have a stable code
# to reference from day one.
PERMISSIONS = [
  { resource: "orders", action: "read", description: "View orders" },
  { resource: "orders", action: "update_status", description: "Change an order's status" },
  { resource: "deliveries", action: "assign", description: "Assign a courier to a delivery" },
  { resource: "payments", action: "review", description: "Review a submitted payment" },
  { resource: "refunds", action: "create", description: "Issue a refund", sensitive: true },
  { resource: "ledger", action: "adjust", description: "Post a manual ledger adjustment", sensitive: true },
  { resource: "users", action: "manage_roles", description: "Assign or revoke roles", sensitive: true }
].freeze

permissions = PERMISSIONS.map do |attrs|
  Permission.find_or_create_by!(resource: attrs[:resource], action: attrs[:action]) do |permission|
    permission.description = attrs[:description]
    permission.sensitive = attrs.fetch(:sensitive, false)
  end
end

platform_admin = Role.find_or_create_by!(code: "platform_admin") do |role|
  role.name = "Platform Admin"
  role.scope_type = "platform"
  role.system_role = true
end

permissions.each do |permission|
  RolePermission.find_or_create_by!(role: platform_admin, permission: permission)
end
