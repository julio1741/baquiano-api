class HealthController < ApplicationController
  def live
    render json: { status: "ok" }, status: :ok
  end

  def ready
    checks = { database: database_ready?, redis: redis_ready? }

    if checks.values.all?
      render json: { status: "ok", checks: checks }, status: :ok
    else
      render json: { status: "unavailable", checks: checks }, status: :service_unavailable
    end
  end

  private

  def database_ready?
    ActiveRecord::Base.connection.select_value("SELECT 1") == 1
  rescue StandardError
    false
  end

  def redis_ready?
    Sidekiq.redis(&:ping) == "PONG"
  rescue StandardError
    false
  end
end
