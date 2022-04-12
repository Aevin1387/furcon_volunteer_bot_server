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
      sections = raw_message.split(' ')
      if sections.length < 3
        respond_with :message, text: t('.format')
        return
      end
      badge_id = Integer(sections[1], exception: false)
      unless badge_id
        respond_with :message, text: t('.format_bad_badge')
        return
      end
      name = sections[2..]
      respond_with :message, text: "You responded with badge, name: #{badge_id}, #{name}"
    end
  end

  def help!(*)
    respond_with :message, text: t('.content')
  end
end