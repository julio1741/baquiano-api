module Api
  module V1
    module Admin
      class SystemSettingsController < Api::V1::BaseController
        include Authenticatable

        def index
          authorize SystemSetting
          settings = SystemSetting.all
          settings = settings.where(scope_type: params[:scope_type]) if params[:scope_type].present?
          settings = settings.where(key: params[:key]) if params[:key].present?
          render json: settings.order(key: :asc, version: :desc).map { |setting| setting_body(setting) }
        end

        def create
          authorize SystemSetting
          setting = Configuration::SetSetting.call(
            scope_type: params[:scope_type], scope_id: params[:scope_id], key: params[:key],
            value: params[:value].respond_to?(:to_unsafe_h) ? params[:value].to_unsafe_h : params[:value],
            value_type: params[:value_type], updated_by: current_user, expires_at: params[:expires_at]
          )
          render json: setting_body(setting), status: :created
        end

        private

        def setting_body(setting)
          {
            id: setting.id, scope_type: setting.scope_type, scope_id: setting.scope_id, key: setting.key,
            value: setting.value, value_type: setting.value_type, version: setting.version,
            effective_at: setting.effective_at, expires_at: setting.expires_at
          }
        end
      end
    end
  end
end
