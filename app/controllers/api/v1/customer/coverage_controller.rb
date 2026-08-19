module Api
  module V1
    module Customer
      # Deliberately unauthenticated — browsing coverage/catalog is common
      # before a customer ever logs in (there is no Customers/Addresses
      # domain yet either; that's Increment 3).
      class CoverageController < Api::V1::BaseController
        def show
          latitude = params.require(:latitude).to_f
          longitude = params.require(:longitude).to_f

          branches = Geography::ListCoveredBranches.call(longitude: longitude, latitude: latitude)
          render json: branches.map { |branch| branch_body(branch) }
        end

        private

        def branch_body(branch)
          {
            id: branch.id,
            name: branch.name,
            slug: branch.slug,
            delivery_model: branch.delivery_model,
            preparation_time_minutes: branch.preparation_time_minutes,
            accepts_cash: branch.accepts_cash,
            accepts_mobile_payment: branch.accepts_mobile_payment,
            accepts_pos_on_delivery: branch.accepts_pos_on_delivery
          }
        end
      end
    end
  end
end
