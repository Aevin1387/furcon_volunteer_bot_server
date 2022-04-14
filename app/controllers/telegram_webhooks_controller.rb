require 'seconds_humanize'

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
          respond_with :message, text: t('.registration_failed')
        end
      rescue
        respond_with :message, text: t('.registration_failed')
      end
    end
  end

  def help!(*)
    respond_with :message, text: t('.content')
  end

  def start_shift!(*)
    logger.info "Running start_shift"
    unless user = User.find_by(telegram_user_id: from['id'], telegram_chat_id: chat['id'])
      reply_with :message, text: t('.please_register')
      return
    end
    if existing_shift = Shift.where(user_id: user.id, end_time: nil).first
      reply_with :message, text: t('.existing_shift')
      return
    end
    shift = Shift.create(user: user, start_time: Time.now)
    logger.info "Sending message #{user.name} has started a shift"
    reply_with :message, text: t('.shift_started')
  end

  def end_shift!(*)
    logger.info "Running end_shift"
    unless user = User.find_by(telegram_user_id: from['id'], telegram_chat_id: chat['id'])
      reply_with :message, text: t('.please_register')
      return
    end
    existing_shift = Shift.where(user_id: user.id, end_time: nil).first
    unless existing_shift
      reply_with :message, text: t('.no_shift')
      return
    end

    existing_shift.update(end_time: Time.now)
    shift_length = TimeDifference.between(existing_shift.start_time, existing_shift.end_time).humanize
    reply_with :message, text: t('.shift_ended', shift_length: shift_length)
  end

  def list_shifts!(*)
    logger.info "Running list_shifts"
    unless user = User.find_by(telegram_user_id: from['id'], telegram_chat_id: chat['id'])
      reply_with :message, text: t('.please_register')
      return
    end
    existing_shifts = Shift.where.not(end_time: nil).where(user: user)
    if existing_shifts.length == 0
      repy_with :message, text: t('.no_shifts')
      return
    end
    shifts_message = ["Your shifts:"]
    existing_shifts.each do |shift|
      start_time_str = shift.start_time.in_time_zone("Central Time (US & Canada)").strftime('%m/%d %H:%M')
      end_time_str = shift.end_time.in_time_zone("Central Time (US & Canada)").strftime('%m/%d %H:%M')
      shift_length = TimeDifference.between(shift.start_time, shift.end_time).humanize
      shifts_message.push("#{start_time_str} - #{end_time_str} (#{shift_length})")
    end
    reply_with :message, text: shifts_message.join("\n")
  end

  def on_shift!(*)
    unless user = User.find_by(telegram_user_id: from['id'], telegram_chat_id: chat['id'])
      reply_with :message, text: t('.please_register')
      return
    end
    shifts = Shift.where(user: User.where(telegram_chat_id: chat['id']), end_time: nil)
    if shifts.length > 0
      on_shift_results = ["Currently on shift:"]
      shifts.each do |shift|
        # TODO: Make the time zone configurable
        on_shift_time = shift.start_time.in_time_zone("Central Time (US & Canada)").strftime('%m/%d %H:%M')
        on_shift_results.push("#{shift.user.name} since #{on_shift_time}")
      end

      reply_with :message, text: on_shift_results.join("\n")
    else
      reply_with :message, text: "No one on shift."
    end
  end

  def all_hours!(*)
    unless current_user = User.find_by(telegram_user_id: from['id'], telegram_chat_id: chat['id'])
      reply_with :message, text: t('.please_register')
      return
    end
    unless current_user.admin
      reply_with :message, text: t('.not_admin')
      return
    end
    users = User.where(telegram_chat_id: chat['id'])
    hours_str = ["Volunteer Hours:"]
    users.each do |user|
      total_shift_length = 0.0
      shifts = Shift.where.not(end_time: nil).where(user: user)
      next if shifts.length == 0
      shifts.each do |shift|
        total_shift_length = total_shift_length + (shift.end_time - shift.start_time).abs
      end
      hours_str.push("\t#{user.name} (#{user.badge_number}): #{SecondsHumanize.new(total_shift_length).humanize}")
    end
    reply_with :message, text: hours_str.join("\n")
  end

  def all_shifts_detailed!(*)
    unless current_user = User.find_by(telegram_user_id: from['id'], telegram_chat_id: chat['id'])
      reply_with :message, text: t('.please_register')
      return
    end
    unless current_user.admin
      reply_with :message, text: t('.not_admin')
      return
    end
    users = User.where(telegram_chat_id: chat['id'])
    shift_str = ["Finished shifts:"]

    users.each do |user|
      shifts = Shift.where.not(end_time: nil).where(user: user)
      shift_str.push("#{user.name} (#{user.badge_number}):") if shifts.length > 0
      shifts.each do |shift|
        start_time_str = shift.start_time.in_time_zone("Central Time (US & Canada)").strftime('%m/%d %H:%M')
        end_time_str = shift.end_time.in_time_zone("Central Time (US & Canada)").strftime('%m/%d %H:%M')
        length = TimeDifference.between(shift.start_time, shift.end_time).humanize
        shift_str.push("\t#{start_time_str} to #{end_time_str} (#{length})")
      end
    end


    if shift_str.length == 1
      reply_with :message, text: "No shifts recorded"
      return
    end
    reply_with :message, text: shift_str.join("\n")
  end
end