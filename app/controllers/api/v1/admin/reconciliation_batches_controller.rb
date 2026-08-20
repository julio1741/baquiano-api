module Api
  module V1
    module Admin
      class ReconciliationBatchesController < Api::V1::BaseController
        include Authenticatable

        def index
          authorize ReconciliationBatch
          render json: ReconciliationBatch.order(created_at: :desc).map { |batch| batch_body(batch) }
        end

        def show
          batch = ReconciliationBatch.find(params[:id])
          authorize batch
          render json: batch_body(batch).merge(items: batch.reconciliation_items.map { |item| item_body(item) })
        end

        def create
          authorize ReconciliationBatch
          batch = Reconciliation::CreateBatch.call(
            provider: params[:provider], payment_method: params[:payment_method], currency: params[:currency],
            period_start: Date.parse(params[:period_start]), period_end: Date.parse(params[:period_end]),
            started_by: current_user,
            external_records: (params[:external_records] || []).map(&:to_unsafe_h).map(&:symbolize_keys)
          )
          render json: batch_body(batch), status: :created
        end

        def complete
          batch = ReconciliationBatch.find(params[:id])
          authorize batch, :complete?
          Reconciliation::CompleteBatch.call(batch: batch, completed_by: current_user)
          render json: batch_body(batch.reload)
        end

        def resolve_item
          item = ReconciliationItem.find(params[:item_id])
          authorize item.reconciliation_batch, :resolve_item?
          Reconciliation::ResolveItem.call(
            item: item, resolved_by: current_user, resolution_code: params[:resolution_code],
            resolution_notes: params[:resolution_notes]
          )
          render json: item_body(item.reload)
        end

        private

        def batch_body(batch)
          {
            id: batch.id, provider: batch.provider, payment_method: batch.payment_method, currency: batch.currency,
            period_start: batch.period_start, period_end: batch.period_end, status: batch.status,
            expected_amount: batch.expected_amount, actual_amount: batch.actual_amount,
            difference_amount: batch.difference_amount, started_at: batch.started_at, completed_at: batch.completed_at
          }
        end

        def item_body(item)
          {
            id: item.id, external_reference: item.external_reference, expected_amount: item.expected_amount,
            actual_amount: item.actual_amount, difference_amount: item.difference_amount, status: item.status,
            resolution_code: item.resolution_code, resolved_at: item.resolved_at
          }
        end
      end
    end
  end
end
