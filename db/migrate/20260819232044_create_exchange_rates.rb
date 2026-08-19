class CreateExchangeRates < ActiveRecord::Migration[8.1]
  def change
    create_table :exchange_rates, id: :uuid do |t|
      t.string :base_currency, null: false
      t.string :quote_currency, null: false
      # Rational (numerator/denominator), never a float — see section 3 of
      # the spec. quote_amount = base_amount * rate_numerator / rate_denominator.
      t.bigint :rate_numerator, null: false
      t.bigint :rate_denominator, null: false
      t.string :source, null: false
      t.string :rate_type, null: false
      t.timestamptz :effective_at, null: false
      t.timestamptz :expires_at
      t.references :created_by_user, null: false, type: :uuid, foreign_key: { to_table: :users, on_delete: :restrict }

      t.timestamps
    end

    add_index :exchange_rates, [ :base_currency, :quote_currency, :effective_at, :rate_type ],
              unique: true, name: "index_exchange_rates_uniqueness"

    add_check_constraint :exchange_rates, "rate_numerator > 0", name: "exchange_rates_rate_numerator_positive"
    add_check_constraint :exchange_rates, "rate_denominator > 0", name: "exchange_rates_rate_denominator_positive"
  end
end
