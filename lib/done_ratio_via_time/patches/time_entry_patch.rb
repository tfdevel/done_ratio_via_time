# Licensed under GNU GPL 2.0
# Author: Tecforce
# Website: http://tecforce.ru

module DoneRatioViaTime
  module Patches
    module TimeEntryPatch
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          validate :hours_overrun
          validate :check_blocked_statuses

          before_save :set_changes  # fix for redmine 3.3.x
          after_save :update_issue_done_ratio
          after_destroy :update_issue_done_ratio
        end
      end

      module InstanceMethods
        def update_issue_done_ratio
          return unless issue && issue.project.try(:module_enabled?,
                                                   :issue_progress)

          if @issue_id_changed
            i = Issue.find_by_id(@issue_id_changed.first)
            set_calculated_done_ratio(i) if i
          end

          set_calculated_done_ratio(issue)
        end

        def hours_overrun
          return unless issue &&
                        project.try(:module_enabled?, :issue_progress) &&
                        DoneRatioSetup.time_overrun_enabled?(project)

          if issue.estimated_hours.present?
            if ([self] + issue.time_entries).uniq.map(&:hours).sum > issue.estimated_hours
              errors.add :base, l(:error_max_spent_time)
            end
          else
            errors.add :base, l(:error_issue_not_estimated)
          end
        end

        def check_blocked_statuses
          return unless issue && DoneRatioSetup.block_spent_time_statuses
          if DoneRatioSetup.block_spent_time_statuses.include?(issue.status)
            errors.add :base, l(:error_issue_status_blocked)
          end
        end

        def set_changes
          @issue_id_changed = changes[:issue_id]
        end

        private

        def set_calculated_done_ratio(i)
          i.init_journal(User.current)
          total_values = i.time_values
          i.update_columns(done_ratio: CalculateDoneRatio.call(i),
                           total_estimated_time: total_values[1],
                           total_spent_time: total_values[0])

          UpdateParentsDoneRatio.call(i)
        end
      end
    end
  end
end

unless TimeEntry.included_modules
                .include?(DoneRatioViaTime::Patches::TimeEntryPatch)
  TimeEntry.send(:include, DoneRatioViaTime::Patches::TimeEntryPatch)
end
