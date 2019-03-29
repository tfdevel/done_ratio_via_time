# Copyright (C) 2018 Tecforce - All rights reserved.

# This file is part of “Done ration via time plugin”.

# “Done ration via time plugin” or its sources can not be copied and/or
# distributed without the express permission of Tecforce. Unauthorized copying
# of this file, via any media, is strictly prohibited.

# Proprietary and confidential.
# For more details please contact sales@tecforce.ru.

module DoneRatioViaTime
  module Patches
    # Types, patches for done ratio calculations
    module VersionPatch
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.extend(ClassMethods)
        base.class_eval do
          alias_method_chain :completed_percent, :new_logic
          alias_method_chain :closed_percent, :new_logic
        end
      end

      module ClassMethods
      end

      module InstanceMethods
        def completed_percent_with_new_logic
          issues = Issue.where(fixed_version_id: self.id)
          estinated_hours_sum = issues.map(&:estimated_hours).compact.sum
          spent_hours_sum = TimeEntry.where(issue_id: issues.map(&:id)).map(&:hours).compact.sum
          if estinated_hours_sum == 0
            0
          else
            100*spent_hours_sum/estinated_hours_sum
          end
        end

        def closed_percent_with_new_logic
          all_issues_sum_estimation = Issue.where(fixed_version_id: self.id).map(&:estimated_hours).compact.sum
          completed_issues_sum_estimation = Issue.where(fixed_version_id: self.id).where.not(closed_on: nil).map(&:estimated_hours).sum
          100*completed_issues_sum_estimation/all_issues_sum_estimation
        end
      end
    end
  end
end

unless Version.included_modules
            .include?(DoneRatioViaTime::Patches::VersionPatch)
  Version.send(:include, DoneRatioViaTime::Patches::VersionPatch)
end
