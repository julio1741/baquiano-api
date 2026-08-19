module Api
  module V1
    module Customer
      class AddressesController < Api::V1::BaseController
        include Authenticatable
        include Api::V1::Customer::CustomerScoped

        def index
          authorize current_customer.addresses.build
          render json: current_customer.addresses.where(archived_at: nil).map { |address| address_body(address) }
        end

        def create
          address = current_customer.addresses.build(address_params.merge(location: point_from_params))
          authorize address
          address.save!
          render json: address_body(address), status: :created
        end

        def update
          address = Address.find(params[:id])
          authorize address

          attrs = address_params
          attrs = attrs.merge(location: point_from_params) if params[:latitude].present? && params[:longitude].present?
          address.update!(attrs)
          render json: address_body(address)
        end

        def destroy
          address = Address.find(params[:id])
          authorize address
          address.update!(archived_at: Time.current)
          head :no_content
        end

        private

        def address_params
          params.permit(:label, :recipient_name, :contact_phone, :city_id, :original_text, :normalized_text,
                        :building, :floor, :apartment, :landmark, :delivery_instructions, :is_default)
        end

        def point_from_params
          RGeo::Geographic.spherical_factory(srid: 4326).point(params[:longitude].to_f, params[:latitude].to_f)
        end

        def address_body(address)
          {
            id: address.id,
            label: address.label,
            recipient_name: address.recipient_name,
            original_text: address.original_text,
            latitude: address.location&.y,
            longitude: address.location&.x,
            is_default: address.is_default,
            covered: address.covered?,
            archived_at: address.archived_at
          }
        end
      end
    end
  end
end
