# Licensed under GNU GPL 2.0
# Author: Tecforce
# Website: http://tecforce.ru

module DoneRatioViaTime
  module Patches
    # Show calculation mode name in issue history
    module IssuesHelperPatch
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          define_method(:render_issue_relations) {} unless base.method_defined?(:render_issue_relations)

          alias_method_chain :show_detail, :done_ratio_calculation_type
          alias_method_chain(:render_issue_relations, :custom_delete_link)
          alias_method_chain :render_half_width_custom_fields_rows, :primary_assessment
          alias_method_chain :issue_spent_hours_details, :done_ratio_calculation_type
          alias_method_chain :issue_estimated_hours_details, :done_ratio_calculation_type
        end
      end

      module InstanceMethods
        def show_detail_with_done_ratio_calculation_type(detail,
                                                         no_html = false,
                                                         options = {})
          if detail.prop_key == 'done_ratio_calculation_type'
            if detail.old_value
              detail.old_value =
                "'#{Issue.done_ratio_calculation_type_name(detail.old_value.to_i)}'"
            end
            if detail.value
              detail.value =
                "'#{Issue.done_ratio_calculation_type_name(detail.value.to_i)}'"
            end
          end
          show_detail_without_done_ratio_calculation_type(detail, no_html, options)
        end

        def render_issue_relations_with_custom_delete_link(issue, relations)
          manage_relations = User.current.allowed_to?(:manage_issue_relations, issue.project)

          s = ''.html_safe
          relations.each do |relation|
            other_issue = relation.other_issue(issue)
            css = "issue hascontextmenu #{other_issue.css_classes}"
            link = manage_relations ? link_to(l(:label_relation_delete),
                                        relation_path(relation, issue_id: issue.id),
                                        :remote => true,
                                        :method => :delete,
                                        :data => {:confirm => l(:text_are_you_sure)},
                                        :title => l(:label_relation_delete),
                                        :class => 'icon-only icon-link-break'
                                       ) : nil

            s << content_tag('tr',
                   content_tag('td', check_box_tag("ids[]", other_issue.id, false, :id => nil), :class => 'checkbox') +
                   content_tag('td', relation.to_s(@issue) {|other| link_to_issue(other, :project => Setting.cross_project_issue_relations?)}.html_safe, :class => 'subject', :style => 'width: 50%') +
                   content_tag('td', other_issue.status, :class => 'status') +
                   content_tag('td', other_issue.start_date, :class => 'start_date') +
                   content_tag('td', other_issue.due_date, :class => 'due_date') +
                   content_tag('td', other_issue.disabled_core_fields.include?('done_ratio') ? '' : progress_bar(other_issue.done_ratio), :class=> 'done_ratio') +
                   content_tag('td', link, :class => 'buttons'),
                   :id => "relation-#{relation.id}",
                   :class => css)
          end

          content_tag('table', s, :class => 'list issues odd-even')
        end

        def render_half_width_custom_fields_rows_with_primary_assessment(issue)
          if DoneRatioSetup.settings[:global][:primary_assessment]
            values = issue.visible_custom_field_values.reject {|value| value.custom_field.full_width_layout?}
            return if values.empty?
            half = (values.size / 2.0).ceil
            issue_fields_rows do |rows|
              values.each_with_index do |value, i|
                css = "cf_#{value.custom_field.id}"
                m = (i < half ? :left : :right)
                primary_assessment_id = DoneRatioSetup.settings[:global][:primary_assessment].to_i
                custom_field_value =
                if value.custom_field.id == primary_assessment_id
                  string = l_hours_short(value.to_s)
                  string << " (#{l(:label_total)}: #{l_hours_short(issue.time_values[2])})" unless issue.invalid_done_ratio_calculation_type
                  string
                else
                  show_value(value)
                end
                rows.send m, custom_field_name_tag(value.custom_field), custom_field_value, :class => css
              end
            end
          else
            render_half_width_custom_fields_rows_without_primary_assessment(issue)
          end
        end

        def issue_spent_hours_details_with_done_ratio_calculation_type(issue)
          if issue.total_spent_hours
            s = issue.spent_hours > 0 ? l_hours_short(issue.spent_hours) : ""
            s << " (#{l(:label_total)}: #{l_hours_short(issue.total_spent_hours)})" unless issue.invalid_done_ratio_calculation_type
            s.html_safe
          end
        end

        def issue_estimated_hours_details_with_done_ratio_calculation_type(issue)
          if issue.total_estimated_hours.present?
            s = issue.estimated_hours.present? ? l_hours_short(issue.estimated_hours) : ""
            s << " (#{l(:label_total)}: #{l_hours_short(issue.total_estimated_hours)})" unless issue.invalid_done_ratio_calculation_type
            s.html_safe
          end
        end
      end
    end
  end
end

unless IssuesHelper.included_modules
                   .include?(DoneRatioViaTime::Patches::IssuesHelperPatch)
  IssuesHelper.send(:include, DoneRatioViaTime::Patches::IssuesHelperPatch)
end
