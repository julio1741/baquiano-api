module Geography
  # Point-in-polygon coverage check, delegated to PostGIS (ST_Covers) rather
  # than computed in Ruby — RGeo doesn't reliably support containment
  # queries on geographic (spherical) geometries, and doing it in the
  # database is both correct and fast (GIST index on service_areas.geometry).
  class CheckCoverage
    def self.call(longitude:, latitude:)
      ServiceArea.active.covering(longitude, latitude)
    end
  end
end
