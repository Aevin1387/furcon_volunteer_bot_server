class User < ApplicationRecord
  validates :telegram_chat_id, presence: true
  validates :telegram_user_id, presence: true
  validates :name, presence: true
  validates :badge_number, presence: true
end
