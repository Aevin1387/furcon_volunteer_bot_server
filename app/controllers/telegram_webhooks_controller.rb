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
      badge_number = Integer(sections[1], exception: false)
      unless badge_number
        respond_with :message, text: t('.format_bad_badge')
        return
      end
      name = sections[2..].join(' ')
      begin
        if User.create(telegram_user_id: from['id'], telegram_chat_id: chat['id'], name: name, badge_number: badge_number)
          respond_with :message, text: t('.registration_complete', badge_number: badge_number, name: name)
        else
          respond_with :message, text: t('registration_failed')
        end
      rescue
        respond_with :message, text: t('registration_failed')
      end
    end
  end

  def help!(*)
    respond_with :message, text: t('.content')
  end

  def start_shift!(*)
    logger.info "Running start_shift"
    unless user = User.find_by(telegram_user_id: from['id'], telegram_chat_id: chat['id'])
      reply_with :message, text: t('please_register')
      return
    end
    if existing_shift = Shift.where(user_id: user.id, end_time: nil).first
      reply_with :message, text: t('existing_shift')
      return
    end
    shift = Shift.create(user: user, start_time: Time.now, chat_id: @chat_id)
    logger.info "Sending message #{user.name} has started a shift"
    reply_with :message, text: t('shift_started')
  end

  def end_shift!(*)
    logger.info "Running end_shift"
    unless user = User.find_by(telegram_user_id: from['id'], telegram_chat_id: chat['id'])
      reply_with :message, text: t('please_register')
      return
    end
    unless existing_shift = Shift.where(user_id: user.id, end_time: nil).first
      reply_with :message, text: t('no_shift')
      return
    end

    existing_shift.update(end_time: Time.now)
    shift_length = TimeDifference.between(shift.start_time, shift.end_time).humanize
    reply_with :message, text: t('shift_ended', shift_length: shift_length)
  end

  def list_shifts!(*)
  end

  def on_shift!(*)
  end

  def all_hours!(*)
  end

  def all_shifts_detailed(*)
  end
end