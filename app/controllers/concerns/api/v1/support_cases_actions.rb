module Api
  module V1
    # Shared by the customer/courier support_cases controllers — same
    # shape as Api::V1::OtpAuthenticatable: the including controller only
    # needs to already provide current_customer and/or current_courier
    # (via CustomerScoped/CourierScoped) for the optional order/delivery
    # linkage to resolve.
    module SupportCasesActions
      extend ActiveSupport::Concern

      included do
        include Authenticatable
      end

      def index
        cases = SupportCase.where(opened_by_user: current_user).order(opened_at: :desc)
        render json: cases.map { |support_case| support_case_body(support_case) }
      end

      def create
        order = owned_order(params[:order_id])
        delivery = owned_delivery(params[:delivery_id])

        support_case = Support::OpenCase.call(
          opened_by: current_user, category: params[:category], subject: params[:subject],
          description: params[:description], customer: order&.customer, order: order, delivery: delivery,
          priority: params[:priority] || "medium"
        )
        render json: support_case_body(support_case), status: :created
      end

      private

      def owned_order(id)
        return nil if id.blank? || !respond_to?(:current_customer, true)

        current_customer.orders.find_by(id: id)
      end

      def owned_delivery(id)
        return nil if id.blank? || !respond_to?(:current_courier, true)

        current_courier.deliveries.find_by(id: id)
      end

      def support_case_body(support_case)
        {
          id: support_case.id, public_number: support_case.public_number, category: support_case.category,
          priority: support_case.priority, status: support_case.status, subject: support_case.subject,
          resolution: support_case.resolution, opened_at: support_case.opened_at
        }
      end
    end
  end
end
