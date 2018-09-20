# Copyright (C) 2018 Tecforce - All rights reserved.

# This file is part of “Done ration via time plugin”.

# “Done ration via time plugin” or its sources can not be copied and/or
# distributed without the express permission of Tecforce. Unauthorized copying
# of this file, via any media, is strictly prohibited.

# Proprietary and confidential.
# For more details please contact sales@tecforce.ru.

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
