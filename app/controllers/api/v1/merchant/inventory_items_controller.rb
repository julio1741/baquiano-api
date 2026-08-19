module Api
  module V1
    module Merchant
      class InventoryItemsController < Api::V1::BaseController
        include Authenticatable

        def index
          branch = Branch.find(params[:branch_id])
          authorize branch, :show?
          render json: branch.inventory_items.map { |item| item_body(item) }
        end

        def create
          branch = Branch.find(params[:branch_id])
          authorize branch, :update?

          item = Catalogs::SetAvailability.call(
            branch: branch,
            updated_by: current_user,
            product: item_params[:product_id].present? ? Product.find(item_params[:product_id]) : nil,
            product_variant: item_params[:product_variant_id].present? ? ProductVariant.find(item_params[:product_variant_id]) : nil,
            availability_status: item_params[:availability_status],
            quantity: item_params[:quantity],
            unavailable_until: item_params[:unavailable_until],
            track_quantity: ActiveModel::Type::Boolean.new.cast(item_params[:track_quantity]) || false
          )
          render json: item_body(item), status: :created
        end

        def update
          item = InventoryItem.find(params[:id])
          authorize item

          item.update!(
            availability_status: item_params[:availability_status] || item.availability_status,
            quantity: item_params.key?(:quantity) ? item_params[:quantity] : item.quantity,
            unavailable_until: item_params.key?(:unavailable_until) ? item_params[:unavailable_until] : item.unavailable_until,
            updated_by_user: current_user
          )
          render json: item_body(item)
        end

        private

        def item_params
          params.permit(:product_id, :product_variant_id, :availability_status, :quantity, :unavailable_until,
                        :track_quantity)
        end

        def item_body(item)
          {
            id: item.id, branch_id: item.branch_id, product_id: item.product_id,
            product_variant_id: item.product_variant_id, availability_status: item.availability_status,
            quantity: item.quantity, track_quantity: item.track_quantity, unavailable_until: item.unavailable_until
          }
        end
      end
    end
  end
end
