module Api
  module V1
    module Customer
      class SupportCasesController < Api::V1::BaseController
        include Api::V1::Customer::CustomerScoped
        include Api::V1::SupportCasesActions
      end
    end
  end
end
