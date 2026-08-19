# frozen_string_literal: true

require "rails_helper"

RSpec.configure do |config|
  config.openapi_root = Rails.root.join("docs/openapi").to_s

  config.openapi_specs = {
    "v1/openapi.yaml" => {
      openapi: "3.1.0",
      info: {
        title: "Baquiano API",
        version: "v1",
        description: "Backend del MVP de Baquiano (pedidos y entregas — Barinas, Venezuela). " \
                      "Consumido por las apps de clientes/repartidores, el portal de comercios y la consola administrativa."
      },
      paths: {},
      servers: [
        { url: "http://localhost:3001", description: "Local development (docker compose)" }
      ],
      tags: [
        { name: "customer", description: "/api/v1/customer" },
        { name: "courier", description: "/api/v1/courier" },
        { name: "merchant", description: "/api/v1/merchant" },
        { name: "admin", description: "/api/v1/admin" },
        { name: "webhooks", description: "/api/v1/webhooks" }
      ]
    }
  }

  config.openapi_format = :yaml
end
