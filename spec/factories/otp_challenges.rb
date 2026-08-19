FactoryBot.define do
  factory :otp_challenge do
    phone_digest { BlindIndex.digest(Phone.e164("58", "4141234567")) }
    purpose { :sign_in }
    code_digest { BlindIndex.digest("123456") }
    expires_at { 5.minutes.from_now }
  end
end
