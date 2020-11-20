# Licensed under GNU GPL 2.0
# Author: Tecforce
# Website: http://tecforce.ru

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
        project_scope = Project.active.joins(:enabled_modules).where("enabled_modules.name = 'issue_progress'").where(default_done_ratio_calculation_type: nil).select(:id)
        Issue.where(project_id: project_scope, done_ratio_calculation_type: Issue::CALCULATION_TYPE_DEFAULT)
      end

    leaves = Issue.all.where("issues.rgt - issues.lft = ?", 1)
    issues = leaves.where.not(id: IssueRelation.where(relation_type: IssueRelation::TYPE_INCLUDE_TIME_FROM).pluck(:issue_from_id))

    count = issues.count
    loop do
      issues.find_each do |issue|
        issue.set_calculated_done_ratio(false)
      end
      issues_from_relations_ids = IssueRelation.where(relation_type: IssueRelation::TYPE_INCLUDE_TIME_FROM, issue_to_id: issues.pluck(:id)).pluck(:issue_from_id)
      parents_ids = issues.pluck(:parent_id).compact
      issues_ids = issues_from_relations_ids + parents_ids
      issues_ids.uniq
      if issues_ids.count == 0
        break
      end
      issues = Issue.where(id: issues_ids)
    end

    issues_with_default_values = Issue.where(total_estimated_time: nil)
    issues_with_default_values.find_each do |issue|
      issue.set_calculated_done_ratio(false)
    end
    Issue.where(total_spent_time: nil).update_all("total_spent_time = 0.0")
    DoneRatioSetup.setting[:job_successful_complete_at] = Time.now
  end
end
