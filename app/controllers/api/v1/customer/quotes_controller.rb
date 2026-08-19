module Api
  module V1
    module Customer
      class QuotesController < Api::V1::BaseController
        include Authenticatable

        def create
          cart = Cart.find(params[:cart_id])
          authorize cart, :show?
          address = Address.find(quote_params[:address_id])

          quote = Pricing::GenerateQuote.call(
            cart: cart, address: address, idempotency_key: quote_params[:idempotency_key]
          )
          render json: quote_body(quote), status: :created
        end

        def show
          quote = Quote.find(params[:id])
          authorize quote
          render json: quote_body(quote)
        end

        private

        def quote_params
          params.permit(:address_id, :idempotency_key)
        end

        def quote_body(quote)
          {
            id: quote.id,
            currency: quote.currency,
            subtotal_amount: quote.subtotal_amount,
            tax_amount: quote.tax_amount,
            delivery_fee_amount: quote.delivery_fee_amount,
            service_fee_amount: quote.service_fee_amount,
            total_amount: quote.total_amount,
            expires_at: quote.expires_at
          }
        end
      end
    end
  end
end
