module RedmineIssueProgress
  module Patches
    # default_done_ratio_calculation_type attribute
    module ProjectPatch
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          safe_attributes 'default_done_ratio_calculation_type'
          after_save :recalculate_issues_done_ratio,
                     if: :default_done_ratio_calculation_type_changed?
        end
      end
    end

    module InstanceMethods
      def recalculate_issues_done_ratio
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
