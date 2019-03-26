module DoneRatioViaTime
  module QueriesHelperPatch
    def self.included(base)
      base.send(:include, InstanceMethods)
      base.class_eval do
        include IssuesExtendHelper
        alias_method_chain :column_value, :relations
      end
    end

    module InstanceMethods
      def column_value_with_relations(column, item, value)
        case column.name
        when :id
          link_to value, issue_path(item)
        when :subject
          link_to value, issue_path(item)
        when :parent
          value ? (value.visible? ? link_to_issue(value, :subject => false) : "##{value.id}") : ''
        when :description
          item.description? ? content_tag('div', textilizable(item, :description), :class => "wiki") : ''
        when :last_notes
          item.last_notes.present? ? content_tag('div', textilizable(item, :last_notes), :class => "wiki") : ''
        when :done_ratio
          progress_bar(value)
        when :relations
          content_tag('span',
            value.to_s(item) {|other| link_to_issue(other, :subject => false, :tracker => false)}.html_safe,
            :class => value.css_classes_for(item))
        when :hours, :estimated_hours
          format_hours(value)
        when :spent_hours
          link_to_if(value > 0, format_hours(value), project_time_entries_path(item.project, :issue_id => "#{item.id}"))
        when :total_spent_hours
          format_hours(value)
        when :attachments
          value.to_a.map {|a| format_object(a)}.join(" ").html_safe
        else
          format_object(value)
        end
      end
    end
  end
end

unless QueriesHelper.included_modules.include?(DoneRatioViaTime::QueriesHelperPatch)
  QueriesHelper.send(:include, DoneRatioViaTime::QueriesHelperPatch)
end
