module Api
  module V1
    module Admin
      class RiskDecisionsController < Api::V1::BaseController
        include Authenticatable

        def index
          authorize RiskDecision
          decisions = RiskDecision.all
          decisions = decisions.where(decision: params[:decision]) if params[:decision].present?
          render json: decisions.order(created_at: :desc).map { |decision| decision_body(decision) }
        end

        def show
          decision = RiskDecision.find(params[:id])
          authorize decision
          render json: decision_body(decision)
        end

        def review
          decision = RiskDecision.find(params[:id])
          authorize decision, :review?
          decision.review!(reviewed_by: current_user)
          render json: decision_body(decision.reload)
        end

        private

        def decision_body(decision)
          {
            id: decision.id, subject_type: decision.subject_type, subject_id: decision.subject_id,
            order_id: decision.order_id, decision: decision.decision, risk_score: decision.risk_score,
            reasons: decision.reasons, rules_version: decision.rules_version,
            reviewed_by_user_id: decision.reviewed_by_user_id, reviewed_at: decision.reviewed_at
          }
        end
      end
    end
  end
end
