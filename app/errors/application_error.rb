class ApplicationError < StandardError
  attr_reader :code, :status, :details

  def initialize(message = nil, code:, status:, details: {})
    @code = code
    @status = status
    @details = details
    super(message || code.to_s.tr("_", " "))
  end
end
