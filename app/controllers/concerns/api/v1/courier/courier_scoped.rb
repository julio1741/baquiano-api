module Api
  module V1
    module Courier
      module CourierScoped
        extend ActiveSupport::Concern

        private

        def current_courier
          current_user.courier ||
            raise(NotFoundError.new("courier profile not found", code: "courier_profile_missing"))
        end
      end
    end
  end
end
