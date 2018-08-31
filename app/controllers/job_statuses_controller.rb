class JobStatusesController < ApplicationController
  before_action :authorize_global

  def index
    last_job_id = IssueProgressSetup.settings[:job_id]

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
    time = IssueProgressSetup.settings[:job_successful_complete_at]
    render json: { status: result,
                   job_successful_complete_at: format_time(time) }
  end
end
