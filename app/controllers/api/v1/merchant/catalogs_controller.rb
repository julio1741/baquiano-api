module Api
  module V1
    module Merchant
      class CatalogsController < Api::V1::BaseController
        include Authenticatable

        def index
          branch = Branch.find(params[:branch_id])
          authorize branch, :show?
          render json: branch.catalogs.map { |catalog| catalog_body(catalog) }
        end

        def create
          branch = Branch.find(params[:branch_id])
          authorize branch, :update?
          catalog = branch.catalogs.create!(catalog_params)
          render json: catalog_body(catalog), status: :created
        end

        def show
          catalog = Catalog.find(params[:id])
          authorize catalog
          render json: catalog_body(catalog)
        end

        def update
          catalog = Catalog.find(params[:id])
          authorize catalog
          catalog.update!(catalog_params)
          render json: catalog_body(catalog)
        end

        def publish
          catalog = Catalog.find(params[:id])
          authorize catalog, :publish?
          Catalogs::PublishCatalog.call(catalog: catalog)
          render json: catalog_body(catalog)
        end

        private

        def catalog_params
          params.permit(:name)
        end

        def catalog_body(catalog)
          {
            id: catalog.id, branch_id: catalog.branch_id, name: catalog.name, status: catalog.status,
            version: catalog.version, published_at: catalog.published_at
          }
        end
      end
    end
  end
end
