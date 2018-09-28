# Copyright (C) 2018 Tecforce - All rights reserved.

# This file is part of “Done ratio via time plugin”.

# “Done ratio via time plugin” or its sources can not be copied and/or
# distributed without the express permission of Tecforce. Unauthorized copying
# of this file, via any media, is strictly prohibited.

# Proprietary and confidential.
# For more details please contact sales@tecforce.ru.

class JobStatusesController < ApplicationController
  before_action :authorize_global

  def index
    last_job_id = DoneRatioSetup.settings[:job_id]

    result =
      if last_job_id.present?
        status = Sidekiq::Status.status(last_job_id)
        case
        when %i[queued working retrying].include?(status)
          :working
        when status == :complete
          :complete
        when %i[failed interrupted].include?(status)
          :failed
        end
      end
    time = DoneRatioSetup.settings[:job_successful_complete_at]
    render json: { status: result,
                   job_successful_complete_at: format_time(time) }
  end
end
