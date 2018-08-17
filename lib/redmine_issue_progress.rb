# must be loaded before IssueQuery
require 'redmine_issue_progress/patches/issue_relation_patch'

Rails.configuration.to_prepare do
  # patches

  # hooks
end
