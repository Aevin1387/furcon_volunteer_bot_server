class CreateUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :users do |t|
      t.integer :telegram_user_id, limit: 8, null: false
      t.integer :telegram_chat_id, limit: 8, null: false
      t.text :name, null: false
      t.integer :badge_number, null: false
      t.boolean :admin, default: false

      t.timestamps
    end
  end
end
