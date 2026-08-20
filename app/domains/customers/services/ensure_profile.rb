module Customers
  # Every user who verifies through the customer app gets a Customer profile
  # (section 4.5: "Un user puede tener un perfil customer") — there's no
  # separate customer registration step, so this runs right after
  # Identity::VerifyOtp succeeds in the customer namespace. Idempotent.
  class EnsureProfile
    def self.call(user:)
      ::Customer.find_or_create_by!(user: user)
    end
  end
end
