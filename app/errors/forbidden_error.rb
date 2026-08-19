class ForbiddenError < ApplicationError
  def initialize(message = nil, code: "forbidden", details: {})
    super(message, code: code, status: :forbidden, details: details)
  end
end
