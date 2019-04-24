namespace :redmine do
  namespace :done_ratio_via_time do
    desc 'Make sure there are no issues with nil values in total spent hours field'
    task :adjust_total_spent_hours => :environment do
      Issue.where(total_spent_hours: nil).each do |issue|
        issue.update_columns(total_spent_hours: 0.0)
      end
    end
  end
end