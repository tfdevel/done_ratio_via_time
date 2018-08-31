module RedmineIssueProgress
  module Hooks
    class ViewsLayoutsHook < Redmine::Hook::ViewListener
      def view_layouts_base_html_head(context = {})
        stylesheet_link_tag(:issue_progress, plugin: 'redmine_issue_progress')
      end
    end
  end
end
