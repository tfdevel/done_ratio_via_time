module RedmineIssueProgress
  module Patches
    # default_done_ratio_calculation_type attribute
    module ProjectPatch
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          safe_attributes 'default_done_ratio_calculation_type'
          after_commit :recalculate_issues_done_ratio
        end
      end
    end

    module InstanceMethods
      def recalculate_issues_done_ratio
        return unless previous_changes.key?(:default_done_ratio_calculation_type)
        job_id = IssueDoneRatioRecalculationWorker.perform_async(project_id: id)
        IssueProgressSetup.setting[:job_id] = job_id
      end
    end
  end
end

unless Project.included_modules
              .include?(RedmineIssueProgress::Patches::ProjectPatch)
  Project.send(:include, RedmineIssueProgress::Patches::ProjectPatch)
end
