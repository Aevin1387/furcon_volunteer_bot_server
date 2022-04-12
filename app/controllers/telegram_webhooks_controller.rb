class TelegramWebhooksController < Telegram::Bot::UpdatesController
  include Telegram::Bot::UpdatesController::MessageContext

  def start!(*)
    respond_with :message, text: t('.content', from: from.as_json, chat: chat.as_json)
  end

  def register!(*)
    if User.find_by(telegram_user_id: from['id'], telegram_chat_id: chat['id'])
      respond_with :message, text: t('.already_registered')
    else
      raw_message = payload['text']
      _, badge_id, name = raw_message.split(' ')
      respond_with :message, text: "You responded with badge, name: #{badge_id}, #{name}"
    end
  end

  def help!(*)
    respond_with :message, text: t('.content')
  end
end