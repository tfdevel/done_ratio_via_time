# Licensed under GNU GPL 2.0
# Author: Tecforce
# Website: http://tecforce.ru

require 'sidekiq'
require 'sidekiq-status'

Sidekiq.configure_client do |config|
  # accepts :expiration (optional)
  Sidekiq::Status.configure_client_middleware config, expiration: 2.hours
  config.redis = { url: 'redis://localhost:6379' }
end

Sidekiq.configure_server do |config|
  # accepts :expiration (optional)
  Sidekiq::Status.configure_server_middleware config, expiration: 2.hours

  # accepts :expiration (optional)
  Sidekiq::Status.configure_client_middleware config, expiration: 2.hours
  config.redis = { url: 'redis://localhost:6379' }
end
