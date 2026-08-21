module Support
  class AssignCase
    def self.call(...) = new(...).call

    def initialize(support_case:, assigned_to:)
      @support_case = support_case
      @assigned_to = assigned_to
    end

    def call
      @support_case.update!(assigned_to_user: @assigned_to)
      @support_case
    end
  end
end
