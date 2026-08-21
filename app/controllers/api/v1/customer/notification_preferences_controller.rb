module Api
  module V1
    module Customer
      class NotificationPreferencesController < Api::V1::BaseController
        include Api::V1::NotificationPreferencesActions
      end
    end
  end
end
