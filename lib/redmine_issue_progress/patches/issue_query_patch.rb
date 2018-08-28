module RedmineIssueProgress
  module Patches
    # calculation type filter for issues
    module IssueQueryPatch
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          alias_method_chain :initialize_available_filters, :calculation_type
        end
      end

      module InstanceMethods
        def initialize_available_filters_with_calculation_type
          initialize_available_filters_without_calculation_type

          return unless project && project.module_enabled?(:issue_progress)
          add_available_filter 'calculation_type',
                               type: :list,
                               values: [[l(:label_mode_auto), 'auto'],
                                        [l(:label_mode_manual), 'manual']],
                               label: :project_module_issue_progress
        end

        def sql_for_calculation_type_field(_field, operator, value)
          manual_modes = [Issue::CALCULATION_TYPE_MANUAL]
          if Issue::CALCULATION_TYPE_MANUAL ==
             IssueProgressSetup.default_calculation_type(project)
            manual_modes << Issue::CALCULATION_TYPE_DEFAULT
          end

          val = value.size > 1 ? 'all' : value.first

          auto_op, manual_op =
            if operator == '='
              ['NOT IN', 'IN']
            else
              ['IN', 'NOT IN']
            end

          case val
          when 'auto'
            "#{Issue.table_name}.done_ratio_calculation_type #{auto_op} (" \
              "#{manual_modes.join(', ')})"
          when 'manual'
            "#{Issue.table_name}.done_ratio_calculation_type #{manual_op} (" \
              "#{manual_modes.join(', ')})"
          when 'all'
            '1=1'
          end
        end
      end
    end
  end
end

unless IssueQuery.included_modules
                 .include?(RedmineIssueProgress::Patches::IssueQueryPatch)
  IssueQuery.send(:include, RedmineIssueProgress::Patches::IssueQueryPatch)
end
