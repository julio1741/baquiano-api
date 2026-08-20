module Api
  module V1
    module Courier
      class DispatchOffersController < Api::V1::BaseController
        include Authenticatable
        include Api::V1::Courier::CourierScoped

        def index
          offers = current_courier.dispatch_offers.where(status: "pending").where("expires_at > ?", Time.current)
            .order(offered_at: :asc)
          render json: offers.map { |offer| offer_body(offer) }
        end

        def accept
          offer = current_courier.dispatch_offers.find(params[:id])
          authorize offer, :respond?
          Dispatch::RespondToOffer.call(offer: offer, courier: current_courier, accept: true)
          render json: offer_body(offer.reload)
        end

        def reject
          offer = current_courier.dispatch_offers.find(params[:id])
          authorize offer, :respond?
          Dispatch::RespondToOffer.call(
            offer: offer, courier: current_courier, accept: false, rejection_reason: params[:rejection_reason]
          )
          render json: offer_body(offer.reload)
        end

        private

        def offer_body(offer)
          {
            id: offer.id, delivery_id: offer.delivery_id, status: offer.status, offered_at: offer.offered_at,
            expires_at: offer.expires_at, score_snapshot: offer.score_snapshot
          }
        end
      end
    end
  end
end
