FactoryBot.define do
  factory :courier_document do
    courier
    document_type { "national_id" }
    attachment_reference { "s3://baquiano-documents/placeholder.jpg" }
    sequence(:document_number) { |n| "V-#{10_000_000 + n}" }
  end
end
