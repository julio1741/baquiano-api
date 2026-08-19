require "rails_helper"

RSpec.describe RoleAssignment, type: :model do
  it "is valid when a platform-scoped role has no organization or branch" do
    role = create(:role, scope_type: :platform)

    expect(build(:role_assignment, role: role)).to be_valid
  end

  it "rejects an organization/branch on a platform-scoped role" do
    role = create(:role, scope_type: :platform)

    assignment = build(:role_assignment, role: role, organization_id: SecureRandom.uuid)

    expect(assignment).not_to be_valid
    expect(assignment.errors[:organization_id]).to be_present
  end

  it "requires an organization for an organization-scoped role" do
    role = create(:role, :organization_scoped)

    assignment = build(:role_assignment, role: role, organization_id: nil)

    expect(assignment).not_to be_valid
    expect(assignment.errors[:organization_id]).to be_present
  end

  it "requires both organization and branch for a branch-scoped role" do
    role = create(:role, :branch_scoped)

    missing_branch = build(:role_assignment, role: role, organization_id: create(:organization).id, branch_id: nil)

    expect(missing_branch).not_to be_valid
    expect(missing_branch.errors[:branch_id]).to be_present
  end

  describe "#revoke!" do
    it "stamps who revoked it, when, and why" do
      assignment = create(:role_assignment)
      admin = create(:user)

      assignment.revoke!(by: admin, reason: "no longer needed")

      expect(assignment.revoked?).to be(true)
      expect(assignment.revoked_by_user).to eq(admin)
      expect(assignment.revocation_reason).to eq("no longer needed")
    end
  end

  describe "#active?" do
    it "is false once revoked or expired, true otherwise" do
      live = create(:role_assignment)
      revoked = create(:role_assignment).tap { |a| a.revoke!(by: create(:user)) }
      expired = create(:role_assignment, expires_at: 1.minute.ago)

      expect(live.active?).to be(true)
      expect(revoked.active?).to be(false)
      expect(expired.active?).to be(false)
    end
  end
end
