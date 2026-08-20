FactoryBot.define do
  factory :delivery_incident do
    delivery
    order { delivery.order }
    reported_by_user { association :user }
    incident_type { "customer_unreachable" }
    severity { "medium" }
    description { "No se pudo contactar al cliente en la direccion de entrega." }
    occurred_at { Time.current }
  end
end
