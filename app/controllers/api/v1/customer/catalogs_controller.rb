module Api
  module V1
    module Customer
      # Read-only, unauthenticated — see CoverageController.
      class CatalogsController < Api::V1::BaseController
        def show
          branch = Branch.find(params[:branch_id])
          catalog = branch.catalogs.find_by(status: "published")
          raise NotFoundError.new("this branch has no published catalog", code: "catalog_not_found") unless catalog

          render json: catalog_body(catalog)
        end

        private

        def catalog_body(catalog)
          {
            id: catalog.id,
            name: catalog.name,
            published_at: catalog.published_at,
            categories: catalog.categories.where(active: true).order(:position).map { |category| category_body(category) }
          }
        end

        def category_body(category)
          {
            id: category.id,
            name: category.name,
            products: category.products.where(active: true).map { |product| product_body(product) }
          }
        end

        def product_body(product)
          {
            id: product.id,
            sku: product.sku,
            name: product.name,
            description: product.description,
            base_price_amount: product.base_price_amount,
            currency: product.currency,
            age_restricted: product.age_restricted,
            prescription_required: product.prescription_required
          }
        end
      end
    end
  end
end
