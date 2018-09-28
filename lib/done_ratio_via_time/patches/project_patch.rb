# Copyright (C) 2018 Tecforce - All rights reserved.

# This file is part of “Done ratio via time plugin”.

# “Done ratio via time plugin” or its sources can not be copied and/or
# distributed without the express permission of Tecforce. Unauthorized copying
# of this file, via any media, is strictly prohibited.

# Proprietary and confidential.
# For more details please contact sales@tecforce.ru.

module DoneRatioViaTime
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
        DoneRatioSetup.setting[:job_id] = job_id
      end
    end
  end
end

unless Project.included_modules
              .include?(DoneRatioViaTime::Patches::ProjectPatch)
  Project.send(:include, DoneRatioViaTime::Patches::ProjectPatch)
end
