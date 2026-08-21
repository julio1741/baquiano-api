module Api
  module V1
    module Courier
      class NotificationsController < Api::V1::BaseController
        include Api::V1::NotificationsActions
      end
    end
  end
end
