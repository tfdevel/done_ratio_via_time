module RedmineIssueProgress
  module Patches
    # Show calculation mode name in issue history
    module IssuesHelperPatch
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          alias_method_chain :show_detail, :done_ratio_calculation_type
          alias_method_chain :render_issue_relations, :custom_delete_link
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
      end
    end
  end
end

unless IssuesHelper.included_modules
                   .include?(RedmineIssueProgress::Patches::IssuesHelperPatch)
  IssuesHelper.send(:include, RedmineIssueProgress::Patches::IssuesHelperPatch)
end
