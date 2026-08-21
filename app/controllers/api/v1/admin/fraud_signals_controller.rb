module Api
  module V1
    module Admin
      # Read-only — a signal is either acted on by creating a RiskDecision
      # (Api::V1::Admin::RiskDecisionsController) or it isn't; there's no
      # per-signal state to change.
      class FraudSignalsController < Api::V1::BaseController
        include Authenticatable

        def index
          authorize FraudSignal
          signals = FraudSignal.all
          signals = signals.where(subject_type: params[:subject_type], subject_id: params[:subject_id]) if
            params[:subject_id].present?
          render json: signals.order(detected_at: :desc).map { |signal| signal_body(signal) }
        end

        private

        def signal_body(signal)
          {
            id: signal.id, subject_type: signal.subject_type, subject_id: signal.subject_id,
            order_id: signal.order_id, payment_intent_id: signal.payment_intent_id, signal_type: signal.signal_type,
            score: signal.score, severity: signal.severity, evidence: signal.evidence,
            detected_at: signal.detected_at
          }
        end
      end
    end
  end
end
