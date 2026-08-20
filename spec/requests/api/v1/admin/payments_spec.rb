require "rails_helper"

RSpec.describe "Admin payments, refunds, reconciliation, settlements, cash", type: :request do
  let(:permission) { create(:permission, resource: "organizations", action: "manage") }
  let(:admin_role) { create(:role, code: "platform_admin") }
  let(:admin) { create(:user) }
  let(:admin_headers) { auth_headers_for(admin, app_type: "admin") }

  before do
    create(:role_permission, role: admin_role, permission: permission)
    create(:role_assignment, user: admin, role: admin_role, assigned_by_user: admin)
  end

  describe "mobile payment review" do
    it "lists pending submissions and approves one" do
      order = create(:order, current_status: "payment_pending", payment_status: "pending", payment_method: "mobile_payment")
      pi = Payments::CreatePaymentIntent.call(order: order)
      submission = Payments::SubmitMobilePayment.call(payment_intent: pi, reference: "REF-ADM-1", amount: pi.amount, paid_at: Time.current)

      get "/api/v1/admin/mobile_payment_submissions", headers: admin_headers
      expect(response.parsed_body.map { |s| s["id"] }).to include(submission.id)

      post "/api/v1/admin/mobile_payment_submissions/#{submission.id}/approve", headers: admin_headers
      expect(response.parsed_body["review_status"]).to eq("confirmed")
      expect(order.reload.current_status).to eq("merchant_pending")
    end

    it "rejects a submission with a reason" do
      order = create(:order, current_status: "payment_pending", payment_status: "pending", payment_method: "mobile_payment")
      pi = Payments::CreatePaymentIntent.call(order: order)
      submission = Payments::SubmitMobilePayment.call(payment_intent: pi, reference: "REF-ADM-2", amount: pi.amount, paid_at: Time.current)

      post "/api/v1/admin/mobile_payment_submissions/#{submission.id}/reject",
           params: { rejection_reason: "monto incorrecto" }, headers: admin_headers, as: :json

      expect(response.parsed_body["review_status"]).to eq("rejected")
    end
  end

  describe "POS payment visibility" do
    it "lists POS payment records" do
      order = create(:order, payment_method: "pos_on_delivery")
      pi = Payments::CreatePaymentIntent.call(order: order)
      Payments::RecordPosPayment.call(payment_intent: pi, confirmed_by: admin)

      get "/api/v1/admin/pos_payment_records", headers: admin_headers
      expect(response.parsed_body.size).to eq(1)
    end
  end

  describe "refunds" do
    it "approves a refund requested by someone other than the approver" do
      order = create(:order, current_status: "delivered", payment_status: "confirmed", payment_method: "cash")
      create(:payment_intent, order: order, customer: order.customer, status: "captured", amount: order.total_amount)
      requester = create(:user)
      refund = Payments::RequestRefund.call(order: order, requested_by: requester, reason_code: "customer_request",
                                             amount: 300, idempotency_key: "admin-refund-1")

      post "/api/v1/admin/refunds/#{refund.id}/approve", headers: admin_headers
      expect(response.parsed_body["status"]).to eq("completed")
    end

    it "denies an admin approving their own refund request" do
      order = create(:order, current_status: "delivered", payment_status: "confirmed", payment_method: "cash")
      create(:payment_intent, order: order, customer: order.customer, status: "captured", amount: order.total_amount)
      refund = Payments::RequestRefund.call(order: order, requested_by: admin, reason_code: "customer_request",
                                             amount: 300, idempotency_key: "admin-refund-2")

      post "/api/v1/admin/refunds/#{refund.id}/approve", headers: admin_headers
      expect(response).to have_http_status(:forbidden)
    end

    it "returns the same result on a repeated (duplicate) refund decision, not a double payout" do
      order = create(:order, current_status: "delivered", payment_status: "confirmed", payment_method: "cash")
      create(:payment_intent, order: order, customer: order.customer, status: "captured", amount: order.total_amount)
      requester = create(:user)
      refund = Payments::RequestRefund.call(order: order, requested_by: requester, reason_code: "customer_request",
                                             amount: 300, idempotency_key: "admin-refund-3")
      post "/api/v1/admin/refunds/#{refund.id}/approve", headers: admin_headers
      expect(response).to have_http_status(:ok)

      post "/api/v1/admin/refunds/#{refund.id}/approve", headers: admin_headers
      expect(response).to have_http_status(:conflict)
    end
  end

  describe "reconciliation" do
    it "creates a batch, surfaces a difference, and requires resolution before completing" do
      order = create(:order, payment_method: "mobile_payment")
      pi = create(:payment_intent, order: order, customer: order.customer, payment_method: "mobile_payment", currency: "VES")
      create(:payment_transaction, payment_intent: pi, provider_transaction_id: "R1", amount: 1_000, occurred_at: Time.current)

      post "/api/v1/admin/reconciliation_batches",
           params: {
             provider: "manual", payment_method: "mobile_payment", currency: "VES",
             period_start: Date.current, period_end: Date.current,
             external_records: [ { external_reference: "R1", amount: 900 } ]
           }, headers: admin_headers, as: :json

      expect(response).to have_http_status(:created)
      batch_id = response.parsed_body["id"]
      expect(response.parsed_body["difference_amount"]).to eq(-100)

      get "/api/v1/admin/reconciliation_batches/#{batch_id}", headers: admin_headers
      item_id = response.parsed_body["items"].first["id"]

      post "/api/v1/admin/reconciliation_batches/#{batch_id}/complete", headers: admin_headers
      expect(response).to have_http_status(:conflict)

      post "/api/v1/admin/reconciliation_batches/items/#{item_id}/resolve",
           params: { resolution_code: "provider_fee_deducted" }, headers: admin_headers, as: :json
      expect(response.parsed_body["status"]).to eq("resolved")

      post "/api/v1/admin/reconciliation_batches/#{batch_id}/complete", headers: admin_headers
      expect(response.parsed_body["status"]).to eq("completed")
    end
  end

  describe "settlements" do
    it "creates, approves, and pays a merchant settlement" do
      branch = create(:branch)
      merchant = branch.merchant
      order = create(:order, branch: branch, organization: branch.organization, merchant: merchant,
                              current_status: "delivered", delivered_at: Time.current, subtotal_amount: 1_000,
                              tax_amount: 0, discount_amount: 0, delivery_fee_amount: 0, service_fee_amount: 0,
                              total_amount: 1_000)

      post "/api/v1/admin/settlements",
           params: { beneficiary_type: "merchant", beneficiary_id: merchant.id, period_start: 1.day.ago.to_date,
                     period_end: Date.current, currency: "VES", idempotency_key: "admin-settle-1" },
           headers: admin_headers, as: :json
      expect(response).to have_http_status(:created)
      settlement_id = response.parsed_body["id"]
      expect(response.parsed_body["gross_amount"]).to eq(1_000)
      expect(order.delivered_at).to be_present

      post "/api/v1/admin/settlements/#{settlement_id}/approve", headers: admin_headers
      expect(response.parsed_body["status"]).to eq("approved")

      post "/api/v1/admin/settlements/#{settlement_id}/mark_paid", params: { payment_reference: "TRF-1" },
                                                                    headers: admin_headers, as: :json
      expect(response.parsed_body["status"]).to eq("paid")
    end
  end

  describe "cash management" do
    it "confirms a courier's cash handover" do
      courier = create(:courier, cash_enabled: true, maximum_cash_exposure: 5_000)
      delivery = create(:delivery, courier: courier)
      delivery.order.update!(payment_method: "cash")
      Payments::CreatePaymentIntent.call(order: delivery.order)
      Cash::CollectCashPayment.call(payment_intent: delivery.order.payment_intent, courier: courier)

      handover = Cash::InitiateHandover.call(courier: courier, received_by: admin, amount: delivery.order.total_amount,
                                              idempotency_key: "admin-handover-1")

      post "/api/v1/admin/cash_handovers/#{handover.id}/confirm", headers: admin_headers
      expect(response.parsed_body["status"]).to eq("confirmed")
      expect(CashBalance.find_by(courier: courier).amount_held).to eq(0)
    end

    it "lets an admin block a courier from cash orders, but denies the courier doing it via their own token" do
      courier = create(:courier, cash_enabled: true, maximum_cash_exposure: 5_000)
      balance = create(:cash_balance, courier: courier)

      patch "/api/v1/admin/cash_balances/#{balance.id}", params: { blocked_for_cash_orders: true },
                                                          headers: admin_headers, as: :json
      expect(response.parsed_body["blocked_for_cash_orders"]).to be true

      balance.update!(blocked_for_cash_orders: false)
      courier_headers = auth_headers_for(courier.user, app_type: "courier")
      patch "/api/v1/admin/cash_balances/#{balance.id}", params: { exposure_limit: 999_999 },
                                                          headers: courier_headers, as: :json
      expect(response).to have_http_status(:forbidden)
      expect(balance.reload.exposure_limit).not_to eq(999_999)
    end
  end
end
