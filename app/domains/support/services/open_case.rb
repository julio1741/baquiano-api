module Support
  # Section 4.16: "No existe un equipo dedicado de soporte durante el
  # lanzamiento. Sin embargo, debe existir trazabilidad mínima de
  # incidencias." — anyone (customer, courier, merchant staff) can open a
  # case about an order/delivery they're actually party to; the
  # authorization for that lives in the controller (same current_customer/
  # current_courier-scoped lookup pattern as everywhere else), not here.
  class OpenCase
    def self.call(...) = new(...).call

    def initialize(opened_by:, category:, subject:, description:, customer: nil, order: nil, delivery: nil,
                   priority: "medium")
      @opened_by = opened_by
      @category = category
      @subject = subject
      @description = description
      @customer = customer
      @order = order
      @delivery = delivery
      @priority = priority
    end

    def call
      SupportCase.create!(
        public_number: generate_public_number, opened_by_user: @opened_by, category: @category, subject: @subject,
        description: @description, customer: @customer, order: @order, delivery: @delivery, priority: @priority,
        status: "open", opened_at: Time.current
      )
    end

    private

    def generate_public_number
      loop do
        candidate = "SC-#{Date.current.strftime('%Y%m%d')}-#{SecureRandom.alphanumeric(6).upcase}"
        break candidate unless SupportCase.exists?(public_number: candidate)
      end
    end
  end
end
