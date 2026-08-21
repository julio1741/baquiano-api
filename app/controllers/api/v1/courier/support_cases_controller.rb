module Api
  module V1
    module Courier
      class SupportCasesController < Api::V1::BaseController
        include Api::V1::Courier::CourierScoped
        include Api::V1::SupportCasesActions
      end
    end
  end
end
