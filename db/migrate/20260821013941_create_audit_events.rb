# Append-only (section 4.18: "La auditoría debe ser append-only") — no
# updated_at. Never written directly; always through Audit::RecordEvent,
# which is the one place responsible for never including tokens, OTP,
# passwords, CVV, PAN, full receipts/documents, or unnecessary PII in
# `change_details`/`metadata`.
#
# Deviates from the spec's literal "changes" column name — Active Record
# already defines an instance method `changes` (dirty-tracking), and
# raises ActiveRecord::DangerousAttributeError at model-load time if a
# column shadows it. Caught before ever building the model.
class CreateAuditEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :audit_events, id: :uuid do |t|
      t.references :actor_user, type: :uuid, foreign_key: { to_table: :users }
      t.string :actor_type, null: false
      t.string :action, null: false
      t.string :resource_type, null: false
      t.uuid :resource_id
      t.references :organization, type: :uuid, foreign_key: true
      t.references :branch, type: :uuid, foreign_key: true
      t.string :request_id
      t.string :correlation_id
      t.inet :ip_address
      t.string :user_agent
      t.jsonb :change_details, null: false, default: {}
      t.jsonb :metadata, null: false, default: {}
      t.timestamptz :occurred_at, null: false

      t.datetime :created_at, null: false
    end

    add_index :audit_events, %i[resource_type resource_id]
    add_index :audit_events, :action
  end
end
