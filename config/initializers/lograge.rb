Rails.application.configure do
  # Configure Lograge
  config.lograge.enabled = true
  config.lograge.base_controller_class = ['ActionController::API', 'AbstractController::Base']
  config.lograge.formatter = Lograge::Formatters::Json.new
  config.lograge.custom_options = lambda do |event|
    exceptions = %w(controller action format id)
    {
      params: event.payload[:params].except(*exceptions)
    }
  end
end

app = Rails.application
if app.config.lograge.enabled
  ActiveSupport::LogSubscriber.log_subscribers.each do |subscriber|
    case subscriber
    when ActionController::LogSubscriber
      Lograge.unsubscribe('updates_controller.bot.telegram', subscriber)
    end
  end
  Lograge::RequestLogSubscriber.attach_to 'updates_controller.bot.telegram'
end