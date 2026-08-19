module Organizations
  class CreateBranch
    def self.call(...) = new(...).call

    def initialize(organization:, merchant:, attributes:)
      @organization = organization
      @merchant = merchant
      @attributes = attributes
    end

    def call
      if @merchant.organization_id != @organization.id
        raise ValidationError.new("merchant does not belong to this organization", code: "merchant_organization_mismatch")
      end

      Branch.create!(@attributes.merge(organization: @organization, merchant: @merchant))
    end
  end
end
