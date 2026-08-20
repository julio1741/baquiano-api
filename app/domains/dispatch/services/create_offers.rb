module Dispatch
  # Section 4.14 of the spec doesn't specify a scoring algorithm beyond
  # "score_snapshot: jsonb" — this is a placeholder MVP policy (nearest
  # online, approved, eligible courier first, by their most recent location
  # ping), not a validated dispatch algorithm. See
  # docs/architecture/decisions.md.
  class CreateOffers
    CANDIDATE_LIMIT = 5
    OFFER_TTL = 30.seconds

    def self.call(...) = new(...).call

    def initialize(delivery:)
      @delivery = delivery
    end

    def call
      candidates = eligible_couriers_by_distance
      raise ConflictError.new("no couriers available", code: "no_couriers_available") if candidates.empty?

      Deliveries::TransitionDelivery.call(delivery: @delivery, to_status: "offered", actor_type: "system")

      now = Time.current
      candidates.map do |candidate|
        DispatchOffer.create!(
          delivery: @delivery, courier_id: candidate[:courier_id], status: "pending",
          offered_at: now, expires_at: now + OFFER_TTL,
          score_snapshot: { distance_meters: candidate[:distance_meters] }
        )
      end
    end

    private

    # LATERAL join to each courier's most recent location ping, ranked by
    # real geographic distance (PostGIS ST_Distance on geography) to the
    # pickup point — never approximated in Ruby.
    def eligible_couriers_by_distance
      sql = ActiveRecord::Base.sanitize_sql_array([
        <<~SQL.squish,
          SELECT couriers.id AS courier_id,
                 ST_Distance(latest_ping.location, ST_SetSRID(ST_MakePoint(?, ?), 4326)::geography) AS distance_meters
          FROM couriers
          INNER JOIN courier_availabilities
            ON courier_availabilities.courier_id = couriers.id
           AND courier_availabilities.ended_at IS NULL
           AND courier_availabilities.status = 'online'
          INNER JOIN LATERAL (
            SELECT location FROM location_pings
            WHERE location_pings.courier_id = couriers.id
            ORDER BY server_received_at DESC
            LIMIT 1
          ) latest_ping ON true
          WHERE couriers.status = 'active'
            AND couriers.approval_status = 'approved'
            AND (
              couriers.courier_type = 'baquiano'
              OR couriers.id IN (
                SELECT courier_id FROM courier_branch_assignments
                WHERE branch_id = ? AND active = true
              )
            )
          ORDER BY distance_meters ASC
          LIMIT ?
        SQL
        @delivery.pickup_location.x, @delivery.pickup_location.y, @delivery.branch_id, CANDIDATE_LIMIT
      ])

      ActiveRecord::Base.connection.select_all(sql).map(&:symbolize_keys)
    end
  end
end
