# Namespace "Catalogs" (plural) — see app/models/catalog.rb and
# docs/architecture/domains.md for why (avoids colliding with the Catalog
# model's own top-level constant name).
module Catalogs
  # TODO: emit CatalogPublished once the domain-events infrastructure
  # exists (Increment 7).
  class PublishCatalog
    def self.call(catalog:)
      raise ConflictError.new("catalog has no products", code: "catalog_empty") unless catalog.products.exists?

      catalog.update!(status: "published", published_at: Time.current, version: catalog.version + 1)
      catalog
    end
  end
end
