module Api
  module V1
    module Admin
      class SettlementsController < Api::V1::BaseController
        include Authenticatable

        def index
          authorize Settlement.new(beneficiary: nil), :show?
          settlements = Settlement.all
          settlements = settlements.where(status: params[:status]) if params[:status].present?
          render json: settlements.order(created_at: :desc).map { |settlement| settlement_body(settlement) }
        end

        def show
          settlement = Settlement.find(params[:id])
          authorize settlement
          render json: settlement_body(settlement)
        end

        def create
          authorize Settlement.new(beneficiary: nil), :create?
          beneficiary = beneficiary_class.find(params[:beneficiary_id])
          settlement = Settlements::Create.call(
            beneficiary: beneficiary, period_start: Date.parse(params[:period_start]),
            period_end: Date.parse(params[:period_end]), currency: params[:currency],
            idempotency_key: params.fetch(:idempotency_key)
          )
          render json: settlement_body(settlement), status: :created
        end

        def approve
          settlement = Settlement.find(params[:id])
          authorize settlement, :approve?
          Settlements::Approve.call(settlement: settlement, approved_by: current_user)
          Audit::RecordEvent.call(
            action: "settlement.approved", resource_type: "Settlement", resource_id: settlement.id,
            metadata: { beneficiary_type: settlement.beneficiary_type, beneficiary_id: settlement.beneficiary_id,
                        net_amount: settlement.net_amount },
            request: request
          )
          render json: settlement_body(settlement.reload)
        end

        def mark_paid
          settlement = Settlement.find(params[:id])
          authorize settlement, :mark_paid?
          Settlements::MarkPaid.call(settlement: settlement, payment_reference: params[:payment_reference])
          Audit::RecordEvent.call(
            action: "settlement.paid", resource_type: "Settlement", resource_id: settlement.id,
            metadata: { beneficiary_type: settlement.beneficiary_type, beneficiary_id: settlement.beneficiary_id,
                        net_amount: settlement.net_amount },
            request: request
          )
          render json: settlement_body(settlement.reload)
        end

        private

        # ::Merchant / ::Courier, not the bare names — see
        # docs/architecture/domains.md: any Api::V1::<role> sibling module
        # (Merchant/Customer/Courier) shadows the top-level model from
        # *any* Api::V1::* controller, not just its own namespace, since
        # Ruby's constant lookup walks every enclosing lexical scope.
        def beneficiary_class
          { "merchant" => ::Merchant, "courier" => ::Courier }.fetch(params[:beneficiary_type]) do
            raise ValidationError.new("unsupported beneficiary_type", code: "invalid_beneficiary_type")
          end
        end

        def settlement_body(settlement)
          {
            id: settlement.id, beneficiary_type: settlement.beneficiary_type,
            beneficiary_id: settlement.beneficiary_id, period_start: settlement.period_start,
            period_end: settlement.period_end, currency: settlement.currency, gross_amount: settlement.gross_amount,
            commission_amount: settlement.commission_amount, adjustment_amount: settlement.adjustment_amount,
            net_amount: settlement.net_amount, status: settlement.status, paid_at: settlement.paid_at
          }
        end
      end
    end
  end
end
