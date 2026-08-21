require "rails_helper"

RSpec.describe "Notifications::Send wired into order transitions", type: :request do
  it "creates and delivers a push notification when the merchant accepts an order" do
    order = create(:order, current_status: "merchant_pending")

    Orders::TransitionOrder.call(order: order, to_status: "merchant_accepted", actor_type: "system")

    notification = Notification.find_by(user: order.customer.user, template_code: "order_accepted")
    expect(notification).to be_present
    expect(notification.order_id).to eq(order.id)

    Notifications::DeliverJob.perform_now(notification.id)
    expect(notification.reload.status).to eq("sent")
  end

  it "does not send a push notification when the customer opted out" do
    order = create(:order, current_status: "merchant_pending")
    create(:notification_preference, user: order.customer.user, notification_type: "order_accepted",
                                      push_enabled: false)

    Orders::TransitionOrder.call(order: order, to_status: "merchant_accepted", actor_type: "system")

    expect(Notification.where(user: order.customer.user, template_code: "order_accepted")).not_to exist
  end

  it "is idempotent — replaying the same notification never double-sends" do
    order = create(:order, current_status: "merchant_pending")
    Orders::TransitionOrder.call(order: order, to_status: "merchant_accepted", actor_type: "system")

    Notifications::Send.call(user: order.customer.user, channel: "push", template_code: "order_accepted",
                              order: order, idempotency_key: "order_accepted:#{order.id}")

    expect(Notification.where(user: order.customer.user, template_code: "order_accepted").count).to eq(1)
  end
end
