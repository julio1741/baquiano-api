module Api
  module V1
    module Customer
      module CustomerScoped
        extend ActiveSupport::Concern

        private

        def current_customer
          current_user.customer ||
            raise(NotFoundError.new("customer profile not found", code: "customer_profile_missing"))
        end
      end
    end
  end
end
