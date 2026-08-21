# Append-only signal log — section 4.17.
class CreateFraudSignals < ActiveRecord::Migration[8.1]
  def change
    create_table :fraud_signals, id: :uuid do |t|
      t.string :subject_type, null: false
      t.uuid :subject_id, null: false
      t.references :order, type: :uuid, foreign_key: true
      t.references :payment_intent, type: :uuid, foreign_key: true
      t.string :signal_type, null: false
      t.decimal :score, precision: 5, scale: 2, null: false
      t.string :severity, null: false
      t.jsonb :evidence, null: false, default: {}
      t.timestamptz :detected_at, null: false

      t.datetime :created_at, null: false
    end

    add_index :fraud_signals, %i[subject_type subject_id]
    add_index :fraud_signals, :signal_type
  end
end
