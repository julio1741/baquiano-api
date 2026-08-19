module Api
  module V1
    module Admin
      class RolesController < Api::V1::BaseController
        include Authenticatable

        def index
          authorize Role
          render json: Role.all.map { |role| role_body(role) }
        end

        def show
          role = Role.find(params[:id])
          authorize role
          render json: role_body(role)
        end

        def create
          role = Role.new(role_params)
          authorize role
          role.save!
          render json: role_body(role), status: :created
        end

        def update
          role = Role.find(params[:id])
          authorize role
          role.update!(role_params)
          render json: role_body(role)
        end

        def destroy
          role = Role.find(params[:id])
          authorize role
          role.destroy!
          head :no_content
        end

        private

        def role_params
          params.permit(:name, :code, :description, :scope_type, :organization_id, :system_role, :active)
        end

        def role_body(role)
          {
            id: role.id, name: role.name, code: role.code, description: role.description,
            scope_type: role.scope_type, organization_id: role.organization_id,
            system_role: role.system_role, active: role.active
          }
        end
      end
    end
  end
end
