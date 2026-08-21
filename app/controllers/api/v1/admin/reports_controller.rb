module Api
  module V1
    module Admin
      # Basic operational reports (section 14: "Reportes operativos
      # básicos") — computed directly from existing tables, no new
      # reporting infrastructure. Deliberately simple: daily order counts,
      # revenue, and cancellation rate for a date range.
      class ReportsController < Api::V1::BaseController
        include Authenticatable

        def orders_by_day
          authorize :report, :view?
          range = date_range
          orders = Order.where(placed_at: range.begin.beginning_of_day..range.end.end_of_day)

          rows = orders.group("DATE(placed_at)").order("DATE(placed_at)").count
          revenue = orders.where(current_status: %w[delivered refunded partially_refunded closed])
            .group("DATE(placed_at)").sum(:total_amount)
          cancelled = orders.where(current_status: "cancelled").group("DATE(placed_at)").count

          render json: rows.map { |date, count|
            {
              date: date, orders: count, revenue_amount: revenue[date] || 0, cancelled_orders: cancelled[date] || 0,
              cancellation_rate: count.zero? ? 0.0 : ((cancelled[date] || 0).to_f / count * 100).round(2)
            }
          }
        end

        private

        def date_range
          period_start = params[:period_start].present? ? Date.parse(params[:period_start]) : 7.days.ago.to_date
          period_end = params[:period_end].present? ? Date.parse(params[:period_end]) : Date.current
          period_start..period_end
        end
      end
    end
  end
end
