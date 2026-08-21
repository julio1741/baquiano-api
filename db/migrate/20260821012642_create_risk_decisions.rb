# Deviates slightly from the literal spec field list (adds updated_at):
# section 4.17 lists only created_at, but reviewed_by_user_id/reviewed_at
# are meant to be filled in later by a human reviewing an automated
# decision, which needs a real update path, not append-only. See
# docs/architecture/decisions.md.
class CreateRiskDecisions < ActiveRecord::Migration[8.1]
  def change
    create_table :risk_decisions, id: :uuid do |t|
      t.string :subject_type, null: false
      t.uuid :subject_id, null: false
      t.references :order, type: :uuid, foreign_key: true
      t.string :decision, null: false
      t.decimal :risk_score, precision: 5, scale: 2, null: false
      t.jsonb :reasons, null: false, default: {}
      t.string :rules_version, null: false
      t.references :reviewed_by_user, type: :uuid, foreign_key: { to_table: :users }
      t.timestamptz :reviewed_at

      t.timestamps
    end

    add_index :risk_decisions, %i[subject_type subject_id]
    add_index :risk_decisions, :decision
  end
end
