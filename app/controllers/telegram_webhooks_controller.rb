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
      name = sections[2..].join(' ')
      if User.create(telegram_user_id: from['id'], telegram_chat_id: chat['id'], name: name, badge_id: badge_id)
        respond_with :message, text: t('.registration_complete', badge_number: badge_id, name: name)
      else
        respond_with :message, text: t('registration_failed')
      end
    end
  end

  def help!(*)
    respond_with :message, text: t('.content')
  end
end