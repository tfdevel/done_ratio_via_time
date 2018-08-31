class IssueDoneRatioRecalculationWorker
  include Sidekiq::Worker
  include Sidekiq::Status::Worker

  sidekiq_options retry: false, backtrace: true

  def perform(options = {})
    issues =
      if options['project_id']
        Issue.where(project_id: options['project_id'],
                    done_ratio_calculation_type: Issue::CALCULATION_TYPE_DEFAULT)
      else
        project_scope = Project.active
                               .joins(:enabled_modules)
                               .where("enabled_modules.name = 'issue_progress'")
                               .where(default_done_ratio_calculation_type: nil)
                               .select(:id)
        Issue.where(project_id: project_scope,
                    done_ratio_calculation_type: Issue::CALCULATION_TYPE_DEFAULT)
      end
    issues.find_each do |issue|
      issue.set_calculated_done_ratio
    end
    IssueProgressSetup.setting[:job_successful_complete_at] = Time.now
  end
end
