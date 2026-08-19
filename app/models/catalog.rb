# Named "Catalogs" (plural) as a domain namespace under app/domains, to avoid
# colliding with this model's own top-level "Catalog" constant — see
# docs/architecture/domains.md.
class Catalog < ApplicationRecord
  belongs_to :branch
  has_many :categories, dependent: :destroy
  has_many :products, dependent: :destroy

  enum :status, { draft: "draft", published: "published", archived: "archived" }, validate: true

  validates :name, presence: true
end
