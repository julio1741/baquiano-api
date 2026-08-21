module Api
  module V1
    module Admin
      class SupportCasesController < Api::V1::BaseController
        include Authenticatable

        def index
          authorize SupportCase.new, :index?
          cases = SupportCase.all
          cases = cases.where(status: params[:status]) if params[:status].present?
          render json: cases.order(opened_at: :desc).map { |support_case| support_case_body(support_case) }
        end

        def show
          support_case = SupportCase.find(params[:id])
          authorize support_case
          render json: support_case_body(support_case)
        end

        def assign
          support_case = SupportCase.find(params[:id])
          authorize support_case, :assign?
          assignee = User.find(params[:assigned_to_user_id])
          Support::AssignCase.call(support_case: support_case, assigned_to: assignee)
          render json: support_case_body(support_case.reload)
        end

        def transition
          support_case = SupportCase.find(params[:id])
          authorize support_case, :transition?
          Support::TransitionCase.call(support_case: support_case, to_status: params[:status],
                                        resolution: params[:resolution])
          render json: support_case_body(support_case.reload)
        end

        private

        def support_case_body(support_case)
          {
            id: support_case.id, public_number: support_case.public_number, category: support_case.category,
            priority: support_case.priority, status: support_case.status, subject: support_case.subject,
            description: support_case.description, resolution: support_case.resolution,
            opened_by_user_id: support_case.opened_by_user_id, assigned_to_user_id: support_case.assigned_to_user_id,
            order_id: support_case.order_id, delivery_id: support_case.delivery_id,
            opened_at: support_case.opened_at, resolved_at: support_case.resolved_at,
            closed_at: support_case.closed_at
          }
        end
      end
    end
  end
end
