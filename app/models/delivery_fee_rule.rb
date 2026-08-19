# No dynamic pricing in the MVP (section 4.8 of the spec) — calculation_type
# "fixed"/"distance" cover the two real cases; "zone"/"configured" are there
# for the schema to accommodate future rules without a migration, not
# implemented here.
class DeliveryFeeRule < ApplicationRecord
  belongs_to :city
  belongs_to :zone, optional: true
  has_many :service_areas, dependent: :nullify

  enum :calculation_type, { fixed: "fixed", distance: "distance", zone: "zone", configured: "configured" },
       validate: true

  validates :name, presence: true
  validates :base_amount, numericality: { greater_than_or_equal_to: 0 }
  validates :currency, presence: true, format: { with: /\A[A-Z]{3}\z/ }
  validates :valid_from, presence: true

  def fee_for(distance_meters: nil)
    amount = case calculation_type
    when "distance"
      raise ArgumentError, "distance_meters is required for a distance-based rule" if distance_meters.nil?

      base_amount + (per_kilometer_amount.to_i * distance_meters / 1000.0).round
    else
      base_amount
    end

    amount = [ amount, minimum_amount ].max if minimum_amount
    amount = [ amount, maximum_amount ].min if maximum_amount
    amount
  end
end
