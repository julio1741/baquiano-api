module Api
  module V1
    module Admin
      class RoleAssignmentsController < Api::V1::BaseController
        include Authenticatable

        def create
          assignment = RoleAssignment.new(assignment_params)
          authorize assignment

          created = AccessControl::AssignRole.call(
            user: assignment.user, role: assignment.role, assigned_by: current_user,
            organization_id: assignment.organization_id, branch_id: assignment.branch_id,
            starts_at: assignment.starts_at || Time.current, expires_at: assignment.expires_at
          )
          Audit::RecordEvent.call(
            action: "role_assignment.created", resource_type: "RoleAssignment", resource_id: created.id,
            organization: created.organization_id && Organization.find_by(id: created.organization_id),
            metadata: { user_id: created.user_id, role_id: created.role_id }, request: request
          )
          render json: assignment_body(created), status: :created
        end

        def destroy
          assignment = RoleAssignment.find(params[:id])
          authorize assignment

          AccessControl::RevokeRole.call(role_assignment: assignment, revoked_by: current_user, reason: params[:reason])
          Audit::RecordEvent.call(
            action: "role_assignment.revoked", resource_type: "RoleAssignment", resource_id: assignment.id,
            metadata: { user_id: assignment.user_id, role_id: assignment.role_id, reason: params[:reason] },
            request: request
          )
          render json: assignment_body(assignment.reload)
        end

        private

        def assignment_params
          params.permit(:user_id, :role_id, :organization_id, :branch_id, :starts_at, :expires_at)
        end

        def assignment_body(assignment)
          {
            id: assignment.id, user_id: assignment.user_id, role_id: assignment.role_id,
            organization_id: assignment.organization_id, branch_id: assignment.branch_id,
            starts_at: assignment.starts_at, expires_at: assignment.expires_at, revoked_at: assignment.revoked_at
          }
        end
      end
    end
  end
end
