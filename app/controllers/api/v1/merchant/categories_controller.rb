module Api
  module V1
    module Merchant
      class CategoriesController < Api::V1::BaseController
        include Authenticatable

        def index
          catalog = Catalog.find(params[:catalog_id])
          authorize catalog, :show?
          render json: catalog.categories.map { |category| category_body(category) }
        end

        def create
          catalog = Catalog.find(params[:catalog_id])
          authorize catalog, :update?
          category = catalog.categories.create!(category_params)
          render json: category_body(category), status: :created
        end

        def show
          category = Category.find(params[:id])
          authorize category
          render json: category_body(category)
        end

        def update
          category = Category.find(params[:id])
          authorize category
          category.update!(category_params)
          render json: category_body(category)
        end

        def destroy
          category = Category.find(params[:id])
          authorize category
          category.destroy!
          head :no_content
        end

        private

        def category_params
          params.permit(:parent_category_id, :name, :description, :position, :active, :available_from,
                        :available_until)
        end

        def category_body(category)
          {
            id: category.id, catalog_id: category.catalog_id, parent_category_id: category.parent_category_id,
            name: category.name, description: category.description, position: category.position,
            active: category.active
          }
        end
      end
    end
  end
end
