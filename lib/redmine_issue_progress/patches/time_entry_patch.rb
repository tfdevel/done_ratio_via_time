module RedmineIssueProgress
  module Patches
    module TimeEntryPatch
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          after_save :update_issue_done_ratio
          after_destroy :update_issue_done_ratio
        end
      end

      module InstanceMethods
        def update_issue_done_ratio
          return unless issue

          issue.init_journal(User.current)
          issue.done_ratio = CalculateDoneRatio.call(issue)
          issue.save
          UpdateParentsDoneRatio.call(issue)
        end
      end
    end
  end
end

unless TimeEntry.included_modules
                .include?(RedmineIssueProgress::Patches::TimeEntryPatch)
  TimeEntry.send(:include, RedmineIssueProgress::Patches::TimeEntryPatch)
end
