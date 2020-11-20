# Licensed under GNU GPL 2.0
# Author: Tecforce
# Website: http://tecforce.ru

class IssueCalculateWorker
  include Sidekiq::Worker
  include Sidekiq::Status::Worker

  sidekiq_options retry: false, backtrace: true

  def perform(id)
    issue = Issue.find id
    issue.set_calculated_done_ratio(false)
  end
end
