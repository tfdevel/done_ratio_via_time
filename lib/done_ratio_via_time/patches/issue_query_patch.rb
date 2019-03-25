# Licensed under GNU GPL 2.0
# Author: Tecforce
# Website: http://tecforce.ru

module DoneRatioViaTime
  module Patches
    # calculation type filter for issues
    module IssueQueryPatch
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          alias_method_chain :initialize_available_filters, :calculation_type
          alias_method_chain :available_columns, :calculation_type
          self.available_columns << QueryColumn.new(:total_estimated_hours,
                                                    :sortable => "#{Issue.table_name}.total_estimated_hours",
                                                    :default_order => 'desc')
        end
      end

      module InstanceMethods
        def initialize_available_filters_with_calculation_type
          initialize_available_filters_without_calculation_type
          add_available_filter 'time_overrun',
                               type: :list,
                               values: [[l(:label_yes), 'true'],
                                        [l(:label_no), 'false']],
                               label: :label_records_with_time_overrun

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
             DoneRatioSetup.default_calculation_type(project)
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

        def sql_for_time_overrun_field(_field, operator, value)
          val = value.size > 1 ? 'all' : value.first

          true_op, false_op =
            if operator == '='
              ['>', '<=']
            else
              ['<=', '>']
            end

          case val
          when 'true'
            'COALESCE(' \
              "(SELECT SUM(#{TimeEntry.table_name}.hours) FROM #{TimeEntry.table_name} " \
                "WHERE #{TimeEntry.table_name}.issue_id = #{Issue.table_name}.id), 0)" \
            "#{true_op} COALESCE(#{Issue.table_name}.estimated_hours, 0)"
          when 'false'
            'COALESCE(' \
              "(SELECT SUM(#{TimeEntry.table_name}.hours) FROM #{TimeEntry.table_name} " \
                "WHERE #{TimeEntry.table_name}.issue_id = #{Issue.table_name}.id), 0)" \
            "#{false_op} COALESCE(#{Issue.table_name}.estimated_hours, 0)"
          when 'all'
            '1=1'
          end
        end

        def available_columns_with_calculation_type
          return @available_columns if @available_columns
          @available_columns = self.class.available_columns.dup
          @available_columns += issue_custom_fields.visible.collect {|cf| QueryCustomFieldColumn.new(cf) }

          if User.current.allowed_to?(:view_time_entries, project, :global => true)
            index = @available_columns.find_index {|column| column.name == :total_estimated_hours}
            index = (index ? index + 1 : -1)
            # insert the column after total_estimated_hours or at the end
            @available_columns.insert index, QueryColumn.new(:spent_hours,
              :sortable => "COALESCE((SELECT SUM(hours) FROM #{TimeEntry.table_name} WHERE #{TimeEntry.table_name}.issue_id = #{Issue.table_name}.id), 0)",
              :default_order => 'desc',
              :caption => :label_spent_time,
              :totalable => true
            )
            @available_columns.insert index+1, QueryColumn.new(:total_spent_hours,
              :sortable => "#{Issue.table_name}.total_spent_hours",
              :default_order => 'desc',
              :caption => :label_total_spent_time
            )
          end

          if User.current.allowed_to?(:set_issues_private, nil, :global => true) ||
            User.current.allowed_to?(:set_own_issues_private, nil, :global => true)
            @available_columns << QueryColumn.new(:is_private, :sortable => "#{Issue.table_name}.is_private", :groupable => true)
          end

          disabled_fields = Tracker.disabled_core_fields(trackers).map {|field| field.sub(/_id$/, '')}
          @available_columns.reject! {|column|
            disabled_fields.include?(column.name.to_s)
          }

          @available_columns
        end
      end
    end
  end
end

unless IssueQuery.included_modules
                 .include?(DoneRatioViaTime::Patches::IssueQueryPatch)
  IssueQuery.send(:include, DoneRatioViaTime::Patches::IssueQueryPatch)
end
