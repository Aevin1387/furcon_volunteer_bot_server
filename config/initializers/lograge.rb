Rails.application.configure do
  # Configure Lograge
  config.lograge.enabled = true
  config.lograge.base_controller_class = ['ActionController::API', 'AbstractController::Base', 'Telegram::Bot::UpdatesController']
  config.lograge.formatter = Lograge::Formatters::Json.new
  config.lograge.custom_options = lambda do |event|
    exceptions = %w(controller action format id)
    {
      params: event.payload[:params].except(*exceptions)
    }
  end
end