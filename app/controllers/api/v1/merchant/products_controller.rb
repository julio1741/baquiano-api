module Api
  module V1
    module Merchant
      class ProductsController < Api::V1::BaseController
        include Authenticatable

        def index
          catalog = Catalog.find(params[:catalog_id])
          authorize catalog, :show?
          render json: catalog.products.map { |product| product_body(product) }
        end

        def create
          catalog = Catalog.find(params[:catalog_id])
          authorize catalog, :update?
          product = catalog.products.create!(product_params)
          render json: product_body(product), status: :created
        end

        def show
          product = Product.find(params[:id])
          authorize product
          render json: product_body(product)
        end

        def update
          product = Product.find(params[:id])
          authorize product
          product.update!(product_params)
          render json: product_body(product)
        end

        def destroy
          product = Product.find(params[:id])
          authorize product
          product.destroy!
          head :no_content
        end

        private

        def product_params
          params.permit(:category_id, :sku, :name, :description, :product_type, :base_price_amount, :currency,
                        :tax_rule_id, :active, :age_restricted, :prescription_required, :preparation_time_minutes,
                        :available_from, :available_until)
        end

        def product_body(product)
          {
            id: product.id, catalog_id: product.catalog_id, category_id: product.category_id, sku: product.sku,
            name: product.name, description: product.description, product_type: product.product_type,
            base_price_amount: product.base_price_amount, currency: product.currency, active: product.active,
            age_restricted: product.age_restricted, prescription_required: product.prescription_required
          }
        end
      end
    end
  end
end
