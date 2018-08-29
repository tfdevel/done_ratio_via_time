# must be loaded before IssueQuery
require 'redmine_issue_progress/patches/issue_relation_patch'

require 'issue_progress_setup'
require 'calculate_done_ratio'
require 'update_parents_done_ratio'

Rails.configuration.to_prepare do
  # patches
  require 'redmine_issue_progress/patches/issue_patch'
  require 'redmine_issue_progress/patches/time_entry_patch'
  require 'redmine_issue_progress/patches/issues_helper_patch'
  require 'redmine_issue_progress/patches/issue_relations_controller_patch'

  # hooks
  require 'redmine_issue_progress/hooks/views_issues_hook'
end
