module Api
  module V1
    module Admin
      # Read-only: the permission catalog is seeded (db/seeds.rb), not
      # managed through the API.
      class PermissionsController < Api::V1::BaseController
        include Authenticatable

        def index
          authorize Permission
          render json: Permission.all.map { |permission| permission_body(permission) }
        end

        private

        def permission_body(permission)
          {
            id: permission.id, resource: permission.resource, action: permission.action,
            code: permission.code, description: permission.description, sensitive: permission.sensitive
          }
        end
      end
    end
  end
end
