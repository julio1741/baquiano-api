module Api
  module V1
    module Admin
      class CourierDocumentsController < Api::V1::BaseController
        include Authenticatable

        def index
          courier = ::Courier.find(params[:courier_id])
          authorize courier, :manage?
          render json: courier.courier_documents.map { |document| document_body(document) }
        end

        def approve
          document = CourierDocument.find(params[:id])
          authorize document.courier, :manage?
          document.update!(status: "approved", reviewed_by_user: current_user, reviewed_at: Time.current)
          render json: document_body(document)
        end

        def reject
          document = CourierDocument.find(params[:id])
          authorize document.courier, :manage?
          document.update!(
            status: "rejected", reviewed_by_user: current_user, reviewed_at: Time.current,
            rejection_reason: params[:rejection_reason]
          )
          render json: document_body(document)
        end

        private

        def document_body(document)
          {
            id: document.id, courier_id: document.courier_id, document_type: document.document_type,
            status: document.status, expires_at: document.expires_at, rejection_reason: document.rejection_reason,
            reviewed_at: document.reviewed_at
          }
        end
      end
    end
  end
end
