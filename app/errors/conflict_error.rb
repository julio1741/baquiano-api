class ConflictError < ApplicationError
  def initialize(message = nil, code: "conflict", details: {})
    super(message, code: code, status: :conflict, details: details)
  end
end
