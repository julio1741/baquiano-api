module Geography
  # Only branch-specific service areas (service_areas.branch_id present)
  # translate to "this branch delivers here" — a branch_id-less service area
  # only means "the platform serves this zone/city at all" (see ServiceArea).
  class ListCoveredBranches
    def self.call(longitude:, latitude:)
      branch_ids = CheckCoverage.call(longitude: longitude, latitude: latitude)
        .where.not(branch_id: nil)
        .select(:branch_id)

      Branch.where(id: branch_ids, status: "active").where(paused_at: nil)
    end
  end
end
