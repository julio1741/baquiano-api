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
  { resource: "users", action: "manage_roles", description: "Assign or revoke roles", sensitive: true },
  { resource: "organizations", action: "manage", description: "CRUD organizations, merchants and branches (admin)" },
  { resource: "branches", action: "manage", description: "Manage a branch's own settings (pause, hours, ...)" },
  { resource: "catalog", action: "manage", description: "Manage a branch's catalog (products, categories, modifiers)" },
  { resource: "availability", action: "manage", description: "Manage a branch's product/variant availability" },
  { resource: "support", action: "manage", description: "Assign and transition support cases" },
  { resource: "risk", action: "review", description: "Review fraud signals and risk decisions", sensitive: true },
  { resource: "audit", action: "read", description: "View the audit log", sensitive: true },
  { resource: "settings", action: "manage", description: "Manage system settings and feature flags", sensitive: true }
].freeze

permissions_by_code = PERMISSIONS.map do |attrs|
  Permission.find_or_create_by!(resource: attrs[:resource], action: attrs[:action]) do |permission|
    permission.description = attrs[:description]
    permission.sensitive = attrs.fetch(:sensitive, false)
  end
end.index_by(&:code)

platform_admin = Role.find_or_create_by!(code: "platform_admin") do |role|
  role.name = "Platform Admin"
  role.scope_type = "platform"
  role.system_role = true
end

permissions_by_code.each_value do |permission|
  RolePermission.find_or_create_by!(role: platform_admin, permission: permission)
end

# Organization-scoped role for a merchant's own staff: can manage their
# branch(es) — pause/resume, hours, catalog, availability, incoming orders —
# but not other merchants, organizations, users or anything financial.
merchant_owner = Role.find_or_create_by!(code: "merchant_owner") do |role|
  role.name = "Merchant Owner"
  role.scope_type = "organization"
  role.system_role = true
end

%w[branches:manage catalog:manage availability:manage orders:read orders:update_status].each do |code|
  RolePermission.find_or_create_by!(role: merchant_owner, permission: permissions_by_code.fetch(code))
end

# Barinas, Venezuela — the only city the MVP launches in (section 1 of the
# spec). The zone's geometry is a rough bounding box around the city, not a
# real administrative boundary; replace with real GIS data before launch.
barinas = City.find_or_create_by!(name: "Barinas", state_name: "Barinas", country_code: "VE") do |city|
  city.timezone = "America/Caracas"
end

rgeo_factory = RGeo::Geographic.spherical_factory(srid: 4326)
barinas_bounding_box = rgeo_factory.multi_polygon([
  rgeo_factory.polygon(
    rgeo_factory.linear_ring([
      rgeo_factory.point(-70.35, 8.55),
      rgeo_factory.point(-70.10, 8.55),
      rgeo_factory.point(-70.10, 8.75),
      rgeo_factory.point(-70.35, 8.75),
      rgeo_factory.point(-70.35, 8.55)
    ])
  )
])

Zone.find_or_create_by!(city: barinas, code: "barinas-centro") do |zone|
  zone.name = "Barinas (rough bounding box)"
  zone.geometry = barinas_bounding_box
  zone.risk_level = "standard"
end

# Placeholder so a quote can be generated end-to-end in development without
# manual setup — the actual fee needs a real commercial decision before
# launch (see docs/architecture/decisions.md).
DeliveryFeeRule.find_or_create_by!(city: barinas, name: "Tarifa fija de referencia") do |rule|
  rule.calculation_type = "fixed"
  rule.base_amount = 150_00
  rule.currency = "VES"
  rule.valid_from = Date.current
end
