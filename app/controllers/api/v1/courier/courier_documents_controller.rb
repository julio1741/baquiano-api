module Api
  module V1
    module Courier
      class CourierDocumentsController < Api::V1::BaseController
        include Authenticatable
        include Api::V1::Courier::CourierScoped

        def index
          authorize current_courier, :show?
          render json: current_courier.courier_documents.map { |document| document_body(document) }
        end

        def create
          authorize current_courier, :update?
          document = current_courier.courier_documents.create!(document_params)
          render json: document_body(document), status: :created
        end

        private

        def document_params
          params.permit(:document_type, :attachment_reference, :document_number, :expires_at)
        end

        def document_body(document)
          {
            id: document.id, document_type: document.document_type, status: document.status,
            expires_at: document.expires_at, rejection_reason: document.rejection_reason
          }
        end
      end
    end
  end
end
