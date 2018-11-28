# Licensed under GNU GPL 2.0
# Author: Tecforce
# Website: http://tecforce.ru

module DoneRatioViaTime
  module Patches
    # default_done_ratio_calculation_type attribute
    module ProjectPatch
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          safe_attributes 'default_done_ratio_calculation_type', 'time_overrun_mode'
          after_commit :recalculate_issues_done_ratio
        end
      end
    end

    module InstanceMethods
      def recalculate_issues_done_ratio
        return unless previous_changes.key?(:default_done_ratio_calculation_type)
        job_id = IssueDoneRatioRecalculationWorker.perform_async(project_id: id)
        DoneRatioSetup.setting[:job_id] = job_id
      end
    end
  end
end

unless Project.included_modules
              .include?(DoneRatioViaTime::Patches::ProjectPatch)
  Project.send(:include, DoneRatioViaTime::Patches::ProjectPatch)
end
