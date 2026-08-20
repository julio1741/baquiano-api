module Api
  module V1
    module Admin
      class OrganizationsController < Api::V1::BaseController
        include Authenticatable

        def index
          authorize Organization
          render json: Organization.all.map { |organization| organization_body(organization) }
        end

        def show
          organization = Organization.find(params[:id])
          authorize organization
          render json: organization_body(organization)
        end

        def create
          organization = Organization.new(organization_params)
          authorize organization
          organization.save!
          render json: organization_body(organization), status: :created
        end

        def update
          organization = Organization.find(params[:id])
          authorize organization
          organization.update!(organization_params)
          render json: organization_body(organization)
        end

        def destroy
          organization = Organization.find(params[:id])
          authorize organization
          organization.destroy!
          head :no_content
        end

        private

        def organization_params
          params.permit(:legal_name, :display_name, :organization_type, :default_currency, :status,
                        :tax_identifier, :contact_phone, :contact_email, :onboarding_status)
        end

        def organization_body(organization)
          {
            id: organization.id,
            legal_name: organization.legal_name,
            display_name: organization.display_name,
            organization_type: organization.organization_type,
            status: organization.status,
            default_currency: organization.default_currency,
            onboarding_status: organization.onboarding_status,
            approved_at: organization.approved_at,
            suspended_at: organization.suspended_at,
            suspension_reason: organization.suspension_reason
          }
        end
      end
    end
  end
end
