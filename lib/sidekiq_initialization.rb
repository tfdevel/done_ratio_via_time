require 'sidekiq'
require 'sidekiq-status'

Sidekiq.configure_client do |config|
  # accepts :expiration (optional)
  Sidekiq::Status.configure_client_middleware config, expiration: 5.minutes
  config.redis = { url: 'redis://localhost:6379' }
end

Sidekiq.configure_server do |config|
  # accepts :expiration (optional)
  Sidekiq::Status.configure_server_middleware config, expiration: 5.minutes

  # accepts :expiration (optional)
  Sidekiq::Status.configure_client_middleware config, expiration: 5.minutes
  config.redis = { url: 'redis://localhost:6379' }
end
