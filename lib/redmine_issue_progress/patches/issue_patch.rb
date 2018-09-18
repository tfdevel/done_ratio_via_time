module RedmineIssueProgress
  module Patches
    # Types, patches for done ratio calculations
    module IssuePatch
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.extend(ClassMethods)
        base.class_eval do
          safe_attributes 'done_ratio_calculation_type',
            if: (proc do |issue, user|
              user.allowed_to?(:edit_done_ratio_calculation_type, issue.project)
            end)

          alias_method_chain :done_ratio_derived?, :auto_calculation
          alias_method_chain :done_ratio, :calculation_type
          alias_method_chain :safe_attributes=, :done_ratio_check

          class << self
            alias_method_chain :use_field_for_done_ratio?, :hide_selector_field
          end
          const_set :CALCULATION_TYPE_DEFAULT, 0
          const_set :CALCULATION_TYPE_MANUAL, 1
          const_set :CALCULATION_TYPE_SELF, 2
          const_set :CALCULATION_TYPE_DESCENDANTS, 3
          const_set :CALCULATION_TYPE_LINKED, 4
          const_set :CALCULATION_TYPE_SELF_AND_DESCENDANTS, 5
          const_set :CALCULATION_TYPE_FULL, 6

          const_set :DONE_RATIO_CALCULATION_TYPES, {
            Issue::CALCULATION_TYPE_DEFAULT => :calculation_type_default,
            Issue::CALCULATION_TYPE_MANUAL => :calculation_type_manual,
            Issue::CALCULATION_TYPE_SELF => :calculation_type_self,
            Issue::CALCULATION_TYPE_DESCENDANTS =>
              :calculation_type_descendants,
            Issue::CALCULATION_TYPE_LINKED => :calculation_type_linked,
            Issue::CALCULATION_TYPE_SELF_AND_DESCENDANTS =>
              :calculation_type_self_and_descendants,
            Issue::CALCULATION_TYPE_FULL => :calculation_type_full
          }.freeze

          validates_inclusion_of :done_ratio_calculation_type,
                                 in: Issue::DONE_RATIO_CALCULATION_TYPES.keys
          validate :manual_calculation_type_allowed?

          after_save :update_issue_done_ratio

          skip_callback :save, :before, :update_done_ratio_from_issue_status,
                        if: -> { project.try(:module_enabled?, :issue_progress) }
          validate :hours_overrun
        end
      end

      module ClassMethods
        def use_field_for_done_ratio_with_hide_selector_field?
          false
        end

        def done_ratio_calculation_type_transformed(issue)
          if issue.done_ratio_calculation_type ==
             Issue::CALCULATION_TYPE_DEFAULT
            IssueProgressSetup.default_calculation_type(issue.project)
          else
            issue.done_ratio_calculation_type
          end
        end

        def done_ratio_calculation_type_name(mode)
          l(Issue::DONE_RATIO_CALCULATION_TYPES[mode])
        end
      end

      module InstanceMethods
        def hours_overrun
          return unless persisted? &&
                        IssueProgressSetup.settings[:global][:enable_time_overrun] == 'true' &&
                        time_entries.all?(&:persisted?)

          if estimated_hours.present?
            if time_entries.map(&:hours).sum > estimated_hours
              errors.add :base, l(:error_max_spent_time)
            end
          else
            errors.add :base, l(:error_issue_not_estimated)
          end
        end

        def done_ratio_derived_with_auto_calculation?
          !project.try(:module_enabled?, :issue_progress)
        end

        def safe_attributes_with_done_ratio_check=(attrs, user = User.current)
          if attrs && project.try(:module_enabled?, :issue_progress)
            new_done_ratio_calculation_type = attrs['done_ratio_calculation_type']
            if new_done_ratio_calculation_type.present?
              new_done_ratio_calculation_type =
                new_done_ratio_calculation_type.to_i
              res =
                if new_done_ratio_calculation_type == Issue::CALCULATION_TYPE_DEFAULT
                  IssueProgressSetup.default_calculation_type(project)
                else
                  new_done_ratio_calculation_type
                end

              attrs.delete('done_ratio') if res != Issue::CALCULATION_TYPE_MANUAL
            elsif Issue.done_ratio_calculation_type_transformed(self) !=
                  Issue::CALCULATION_TYPE_MANUAL
              attrs.delete('done_ratio')
            end
          end
          send(:safe_attributes_without_done_ratio_check=, attrs, user)
        end

        def done_ratio_with_calculation_type
          if project.try(:module_enabled?, :issue_progress)
            read_attribute(:done_ratio)
          else
            done_ratio_without_calculation_type
          end
        end

        def update_issue_done_ratio
          return unless project.try(:module_enabled?, :issue_progress) &&
                        (estimated_hours_changed? ||
                          done_ratio_calculation_type_changed? ||
                          parent_id_changed?)

          set_calculated_done_ratio
        end

        def set_calculated_done_ratio
          current_issue_journal = current_journal || init_journal(User.current)
          update_column(:done_ratio, CalculateDoneRatio.call(self))
          current_issue_journal.save
          UpdateParentsDoneRatio.call(self)
        end

        def manual_calculation_type_allowed?
          return unless Issue.done_ratio_calculation_type_transformed(self) ==
                        Issue::CALCULATION_TYPE_MANUAL && tracker_id
          if IssueProgressSetup.settings[:global][:trackers_with_disabled_manual_mode]
                               .to_a
                               .include?(tracker_id.to_s)
            errors.add :base, l(:error_manual_mode_is_restricted)
          end
        end
      end
    end
  end
end

unless Issue.included_modules
            .include?(RedmineIssueProgress::Patches::IssuePatch)
  Issue.send(:include, RedmineIssueProgress::Patches::IssuePatch)
end
