require "rails_helper"

RSpec.describe AccessControl::HasPermission do
  let(:permission) { create(:permission, resource: "orders", action: "read") }
  let(:user) { create(:user) }
  let(:organization) { create(:organization) }
  let(:other_organization) { create(:organization) }
  let(:branch) { create(:branch, organization: organization) }

  def grant(role, organization_id: nil, branch_id: nil)
    create(:role_permission, role: role, permission: permission)
    create(:role_assignment, user: user, role: role, assigned_by_user: user,
                              organization_id: organization_id, branch_id: branch_id)
  end

  it "is false for a user with no matching assignment" do
    expect(described_class.call(user: user, code: "orders:read")).to be(false)
  end

  it "is false for a nil user" do
    expect(described_class.call(user: nil, code: "orders:read")).to be(false)
  end

  it "a platform-scoped grant applies everywhere" do
    grant(create(:role, scope_type: :platform))

    expect(described_class.call(user: user, code: "orders:read")).to be(true)
    expect(described_class.call(user: user, code: "orders:read", organization_id: organization.id)).to be(true)
    expect(
      described_class.call(user: user, code: "orders:read", organization_id: organization.id, branch_id: branch.id)
    ).to be(true)
  end

  it "an organization-scoped grant applies within that organization but not elsewhere" do
    grant(create(:role, :organization_scoped), organization_id: organization.id)

    expect(described_class.call(user: user, code: "orders:read", organization_id: organization.id)).to be(true)
    expect(
      described_class.call(user: user, code: "orders:read", organization_id: organization.id, branch_id: branch.id)
    ).to be(true)
    expect(described_class.call(user: user, code: "orders:read", organization_id: other_organization.id)).to be(false)
    expect(described_class.call(user: user, code: "orders:read")).to be(false)
  end

  it "a branch-scoped grant applies only to that branch" do
    other_branch = create(:branch, organization: organization)
    grant(create(:role, :branch_scoped), organization_id: organization.id, branch_id: branch.id)

    expect(
      described_class.call(user: user, code: "orders:read", organization_id: organization.id, branch_id: branch.id)
    ).to be(true)
    expect(
      described_class.call(user: user, code: "orders:read", organization_id: organization.id, branch_id: other_branch.id)
    ).to be(false)
    expect(described_class.call(user: user, code: "orders:read", organization_id: organization.id)).to be(false)
  end

  it "ignores a revoked assignment" do
    role = create(:role, scope_type: :platform)
    grant(role)
    user.role_assignments.last.revoke!(by: user)

    expect(described_class.call(user: user, code: "orders:read")).to be(false)
  end

  it "ignores an expired assignment" do
    role = create(:role, scope_type: :platform)
    create(:role_permission, role: role, permission: permission)
    create(:role_assignment, user: user, role: role, assigned_by_user: user, expires_at: 1.minute.ago)

    expect(described_class.call(user: user, code: "orders:read")).to be(false)
  end

  it "ignores an assignment that hasn't started yet" do
    role = create(:role, scope_type: :platform)
    create(:role_permission, role: role, permission: permission)
    create(:role_assignment, user: user, role: role, assigned_by_user: user, starts_at: 1.hour.from_now)

    expect(described_class.call(user: user, code: "orders:read")).to be(false)
  end
end
