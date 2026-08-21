class CreateNotificationPreferences < ActiveRecord::Migration[8.1]
  def change
    create_table :notification_preferences, id: :uuid do |t|
      t.references :user, null: false, type: :uuid, foreign_key: true
      t.string :notification_type, null: false
      t.boolean :push_enabled, null: false, default: true
      t.boolean :sms_enabled, null: false, default: true
      t.boolean :email_enabled, null: false, default: true

      t.timestamps
    end

    add_index :notification_preferences, %i[user_id notification_type], unique: true
  end
end
