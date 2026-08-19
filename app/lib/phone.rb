# Normalizes a (country_code, national_number) pair into E.164 so the same
# phone number always produces the same blind-index digest regardless of
# how it was typed (with/without leading 0, spaces, dashes, ...).
module Phone
  def self.e164(country_code, number)
    return nil if country_code.blank? || number.blank?

    cc = country_code.to_s.gsub(/\D/, "")
    national = number.to_s.gsub(/\D/, "").sub(/\A0+/, "")
    "+#{cc}#{national}"
  end
end
