# Each domain folder (app/domains/orders, app/domains/payments, ...) is an
# autoload root by default. Collapsing the role folder inside it (services,
# policies, models, ...) so `app/domains/orders/services/place_order.rb`
# resolves to `Orders::PlaceOrder`, matching the command names used across
# the spec (Orders::PlaceOrder, Payments::CreatePaymentIntent, ...).
Rails.autoloaders.each do |autoloader|
  autoloader.collapse(Rails.root.join("app/domains/*/*"))
end
