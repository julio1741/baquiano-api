module Api
  module V1
    module Admin
      class FeatureFlagsController < Api::V1::BaseController
        include Authenticatable

        def index
          authorize FeatureFlag
          render json: FeatureFlag.all.map { |flag| flag_body(flag) }
        end

        def show
          flag = FeatureFlag.find(params[:id])
          authorize flag
          render json: flag_body(flag)
        end

        def create
          flag = FeatureFlag.new(flag_params.merge(created_by_user: current_user, updated_by_user: current_user))
          authorize flag
          flag.save!
          render json: flag_body(flag), status: :created
        end

        def update
          flag = FeatureFlag.find(params[:id])
          authorize flag
          flag.update!(flag_params.merge(updated_by_user: current_user))
          render json: flag_body(flag)
        end

        private

        def flag_params
          params.permit(:key, :description, :enabled).merge(rules: rules_param)
        end

        def rules_param
          params[:rules].respond_to?(:to_unsafe_h) ? params[:rules].to_unsafe_h : (params[:rules] || {})
        end

        def flag_body(flag)
          {
            id: flag.id, key: flag.key, description: flag.description, enabled: flag.enabled, rules: flag.rules
          }
        end
      end
    end
  end
end
