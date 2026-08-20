module Api
  module V1
    module Admin
      # NOTE: references the Merchant model as ::Merchant throughout — bare
      # `Merchant` inside Api::V1::* resolves to the Api::V1::Merchant
      # routing namespace module instead, since Ruby's lexical constant
      # lookup finds that nested module before the top-level model class.
      class MerchantsController < Api::V1::BaseController
        include Authenticatable

        def index
          authorize ::Merchant
          render json: ::Merchant.all.map { |merchant| merchant_body(merchant) }
        end

        def show
          merchant = ::Merchant.find(params[:id])
          authorize merchant
          render json: merchant_body(merchant)
        end

        def create
          authorize ::Merchant
          organization = Organization.find(merchant_params[:organization_id])
          merchant = ::Merchant.create!(merchant_params.except(:organization_id).merge(organization: organization))
          render json: merchant_body(merchant), status: :created
        end

        def update
          merchant = ::Merchant.find(params[:id])
          authorize merchant
          merchant.update!(merchant_params.except(:organization_id))
          render json: merchant_body(merchant)
        end

        def destroy
          merchant = ::Merchant.find(params[:id])
          authorize merchant
          merchant.destroy!
          head :no_content
        end

        private

        def merchant_params
          params.permit(:organization_id, :slug, :description, :vertical, :status,
                        :accepts_baquiano_couriers, :accepts_own_couriers, :commission_rate_basis_points)
        end

        def merchant_body(merchant)
          {
            id: merchant.id,
            organization_id: merchant.organization_id,
            slug: merchant.slug,
            description: merchant.description,
            vertical: merchant.vertical,
            status: merchant.status,
            accepts_baquiano_couriers: merchant.accepts_baquiano_couriers,
            accepts_own_couriers: merchant.accepts_own_couriers,
            commission_rate_basis_points: merchant.commission_rate_basis_points
          }
        end
      end
    end
  end
end
