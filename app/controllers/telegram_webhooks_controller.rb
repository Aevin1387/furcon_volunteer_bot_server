class TelegramWebhooksController < Telegram::Bot::UpdatesController
  include Telegram::Bot::UpdatesController::MessageContext

  def start!(*)
    respond_with :message, text: t('.content', from: from.as_json, chat: chat.as_json)
  end

  def register!(text = nil, *)
    if User.find_by(telegram_user_id: from['id'], telegram_chat_id: chat['id'])
      respond_with :message, text: t('.already_registered')
    else
      respond_with :message, text: "You responded with: #{text}"
    end
  end

  def help!(*)
    respond_with :message, text: t('.content')
  end
end