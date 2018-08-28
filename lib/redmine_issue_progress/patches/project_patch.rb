module RedmineIssueProgress
  module Patches
    # default_done_ratio_calculation_type attribute
    module ProjectPatch
      def self.included(base)
        base.class_eval do
          safe_attributes 'default_done_ratio_calculation_type'
        end
      end
    end
  end
end

unless Project.included_modules
              .include?(RedmineIssueProgress::Patches::ProjectPatch)
  Project.send(:include, RedmineIssueProgress::Patches::ProjectPatch)
end
