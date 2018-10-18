# Licensed under GNU GPL 2.0
# Author: Tecforce
# Website: http://tecforce.ru

module DoneRatioViaTime
  module Patches
    module EnabledModulePatch
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          alias_method_chain :module_enabled, :issue_progress
          after_commit :perform_recalculation
        end
      end
    end

    module InstanceMethods
      def module_enabled_with_issue_progress
        module_enabled_without_issue_progress
        return unless name == 'issue_progress'
        @is_recalculation_required = true
      end

      private

      def perform_recalculation
        return unless @is_recalculation_required && project_id
        job_id = IssueDoneRatioRecalculationWorker.perform_async(project_id:
          project_id)
        DoneRatioSetup.setting[:job_id] = job_id
      end
    end
  end
end

unless EnabledModule.included_modules
                    .include?(DoneRatioViaTime::Patches::EnabledModulePatch)
  EnabledModule.send(:include, DoneRatioViaTime::Patches::EnabledModulePatch)
end
