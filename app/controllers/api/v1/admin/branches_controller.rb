module Api
  module V1
    module Admin
      class BranchesController < Api::V1::BaseController
        include Authenticatable

        def index
          authorize Branch
          render json: Branch.all.map { |branch| branch_body(branch) }
        end

        def show
          branch = Branch.find(params[:id])
          authorize branch
          render json: branch_body(branch)
        end

        def create
          authorize Branch, :create?
          organization = Organization.find(branch_params[:organization_id])
          merchant = ::Merchant.find(branch_params[:merchant_id]) # see note in Admin::MerchantsController

          branch = Organizations::CreateBranch.call(organization: organization, merchant: merchant, attributes: branch_attributes)
          render json: branch_body(branch), status: :created
        end

        def update
          branch = Branch.find(params[:id])
          authorize branch
          branch.update!(branch_attributes)
          render json: branch_body(branch)
        end

        def destroy
          branch = Branch.find(params[:id])
          authorize branch
          branch.destroy!
          head :no_content
        end

        def pause
          branch = Branch.find(params[:id])
          authorize branch
          Organizations::PauseBranch.call(branch: branch, reason: params[:reason])
          render json: branch_body(branch)
        end

        def resume
          branch = Branch.find(params[:id])
          authorize branch
          Organizations::ResumeBranch.call(branch: branch)
          render json: branch_body(branch)
        end

        private

        def branch_params
          params.permit(:organization_id, :merchant_id, :name, :slug, :phone, :email, :status, :delivery_model,
                        :address_text, :address_reference, :latitude, :longitude, :preparation_time_minutes,
                        :minimum_order_amount, :minimum_order_currency, :accepts_cash, :accepts_mobile_payment,
                        :accepts_pos_on_delivery)
        end

        def branch_attributes
          attrs = branch_params.except(:organization_id, :merchant_id, :latitude, :longitude).to_h.symbolize_keys

          if branch_params[:latitude].present? && branch_params[:longitude].present?
            attrs[:location] = RGeo::Geographic.spherical_factory(srid: 4326)
              .point(branch_params[:longitude].to_f, branch_params[:latitude].to_f)
          end

          attrs
        end

        def branch_body(branch)
          {
            id: branch.id,
            organization_id: branch.organization_id,
            merchant_id: branch.merchant_id,
            name: branch.name,
            slug: branch.slug,
            status: branch.status,
            delivery_model: branch.delivery_model,
            address_text: branch.address_text,
            latitude: branch.location&.y,
            longitude: branch.location&.x,
            preparation_time_minutes: branch.preparation_time_minutes,
            accepts_cash: branch.accepts_cash,
            accepts_mobile_payment: branch.accepts_mobile_payment,
            accepts_pos_on_delivery: branch.accepts_pos_on_delivery,
            paused_at: branch.paused_at,
            pause_reason: branch.pause_reason
          }
        end
      end
    end
  end
end
