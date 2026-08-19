module Api
  module V1
    module Merchant
      class BranchesController < Api::V1::BaseController
        include Authenticatable

        def index
          branches = AccessControl::AccessibleBranches.call(user: current_user)
          render json: branches.map { |branch| branch_body(branch) }
        end

        def show
          branch = find_branch
          authorize branch
          render json: branch_body(branch)
        end

        def update
          branch = find_branch
          authorize branch
          branch.update!(branch_params)
          render json: branch_body(branch)
        end

        def pause
          branch = find_branch
          authorize branch
          Organizations::PauseBranch.call(branch: branch, reason: params[:reason])
          render json: branch_body(branch)
        end

        def resume
          branch = find_branch
          authorize branch
          Organizations::ResumeBranch.call(branch: branch)
          render json: branch_body(branch)
        end

        private

        def find_branch
          Branch.find(params[:id])
        end

        def branch_params
          params.permit(:preparation_time_minutes, :minimum_order_amount, :minimum_order_currency,
                        :accepts_cash, :accepts_mobile_payment, :accepts_pos_on_delivery)
        end

        def branch_body(branch)
          {
            id: branch.id,
            name: branch.name,
            slug: branch.slug,
            status: branch.status,
            delivery_model: branch.delivery_model,
            preparation_time_minutes: branch.preparation_time_minutes,
            accepts_cash: branch.accepts_cash,
            accepts_mobile_payment: branch.accepts_mobile_payment,
            accepts_pos_on_delivery: branch.accepts_pos_on_delivery,
            paused_at: branch.paused_at,
            pause_reason: branch.pause_reason
          }
        end
      end
    end
  end
end
