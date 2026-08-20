require "rails_helper"

RSpec.describe "Delivery cannot complete without a captured payment", type: :model do
  it "blocks confirm_delivery when the order's payment was never captured" do
    courier = create(:courier)
    order = create(:order, current_status: "courier_at_customer", payment_method: "cash")
    create(:payment_intent, order: order, customer: order.customer, status: "created")
    delivery = create(:delivery, order: order, status: "at_customer", courier: courier,
                                  delivery_pin_digest: BlindIndex.digest("1234"))

    expect {
      Deliveries::TransitionDelivery.call(delivery: delivery, to_status: "delivered", actor_type: "courier",
                                           actor_courier: courier, pin: "1234")
    }.to raise_error(ConflictError, /captured/)
  end

  it "allows confirm_delivery once the payment is captured" do
    courier = create(:courier)
    order = create(:order, current_status: "courier_at_customer", payment_method: "cash")
    create(:payment_intent, order: order, customer: order.customer, status: "captured")
    delivery = create(:delivery, order: order, status: "at_customer", courier: courier,
                                  delivery_pin_digest: BlindIndex.digest("1234"))

    Deliveries::TransitionDelivery.call(delivery: delivery, to_status: "delivered", actor_type: "courier",
                                         actor_courier: courier, pin: "1234")
    expect(delivery.reload.status).to eq("delivered")
  end
end
