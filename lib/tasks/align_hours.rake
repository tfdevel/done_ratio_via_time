namespace :redmine do
  namespace :done_ratio_via_time do
    desc 'Align issues estimates and spent hours'
    task :align_hours => :environment do
      puts "Current time: #{Time.now}, updated issue ids:"
      User.current = User.active.where(admin: true).first
      project_scope = Project.active
                             .joins(:enabled_modules)
                             .where("enabled_modules.name = 'issue_progress'")
                             .select(:id)
      Issue.where(project_id: project_scope)
           .where(status_id: DoneRatioSetup.settings[:global][:statuses_for_hours_alignment].to_a)
           .includes(:time_entries).find_each do |issue|
        spent_hours = issue.time_entries.map(&:hours).sum || 0.0
        next if spent_hours == issue.estimated_hours
        current_issue_journal = issue.current_journal || issue.init_journal(User.current)
        issue.update_columns(estimated_hours: spent_hours,
                            total_spent_time: issue.time_values[0],
                            total_estimated_time: issue.time_values[1])
        current_issue_journal.save
        done_ratio = CalculateDoneRatio.call(issue)
        if done_ratio != issue.done_ratio
          current_issue_journal = issue.current_journal || issue.init_journal(User.current)
          issue.update_column(:done_ratio, done_ratio)
          current_issue_journal.save
        end
        UpdateParentsDoneRatio.call(issue)
        puts issue.id
      end
    end
  end
end
