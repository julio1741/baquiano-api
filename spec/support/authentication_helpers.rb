module AuthenticationHelpers
  # Bypasses the OTP dance for specs that need an authenticated context but
  # aren't testing the auth flow itself.
  def auth_headers_for(user, app_type: "customer")
    device = create(:device, user: user, app_type: app_type)
    issued = Identity::IssueSession.call(user: user, device: device)
    { "Authorization" => "Bearer #{issued.access_token}" }
  end
end
