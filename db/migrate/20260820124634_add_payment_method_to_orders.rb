# payment_method was only ever a transient Orders::PlaceOrder parameter
# (used to decide the initial status, then discarded) — a real gap once
# Payments needs to know which method a placed order actually used.
class AddPaymentMethodToOrders < ActiveRecord::Migration[8.1]
  def change
    add_column :orders, :payment_method, :string
  end
end
