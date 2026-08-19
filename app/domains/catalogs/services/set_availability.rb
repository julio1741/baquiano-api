module Catalogs
  class SetAvailability
    def self.call(...) = new(...).call

    def initialize(branch:, updated_by:, availability_status:, product: nil, product_variant: nil,
                   quantity: nil, unavailable_until: nil, track_quantity: false)
      @branch = branch
      @updated_by = updated_by
      @product = product
      @product_variant = product_variant
      @availability_status = availability_status
      @quantity = quantity
      @unavailable_until = unavailable_until
      @track_quantity = track_quantity
    end

    def call
      item = InventoryItem.find_or_initialize_by(branch: @branch, product: @product, product_variant: @product_variant)
      item.assign_attributes(
        availability_status: @availability_status,
        quantity: @quantity,
        unavailable_until: @unavailable_until,
        track_quantity: @track_quantity,
        updated_by_user: @updated_by
      )
      item.save!
      item
    end
  end
end
