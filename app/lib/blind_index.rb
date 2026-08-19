# HMAC-SHA256 digest for the `*_digest` columns used to search encrypted
# fields (phone, email, document numbers, ...) without decrypting them or
# relying on deterministic encryption. Callers normalize the value first
# (e.g. E.164 for phone numbers) so equal-but-differently-formatted inputs
# still match.
module BlindIndex
  def self.digest(value)
    return nil if value.blank?

    OpenSSL::HMAC.hexdigest("SHA256", pepper, value.to_s)
  end

  def self.pepper
    @pepper ||= ENV.fetch("BLIND_INDEX_PEPPER")
  end
end
