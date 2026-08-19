# Structured, one-line-per-request JSON logs. Request params are never
# included by default, keeping PII out of logs per the spec's requirement.
Rails.application.configure do
  config.lograge.enabled = true
  config.lograge.formatter = Lograge::Formatters::Json.new

  config.lograge.custom_options = lambda do |_event|
    {
      request_id: Current.request_id,
      correlation_id: Current.correlation_id
    }
  end
end
