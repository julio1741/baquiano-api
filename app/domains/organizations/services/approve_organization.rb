module Organizations
  # TODO: emit MerchantApproved once the domain-events infrastructure
  # exists (Increment 7).
  class ApproveOrganization
    def self.call(organization:)
      organization.approve!
      organization
    end
  end
end
