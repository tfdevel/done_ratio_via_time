module RedmineIssueProgress
  module Hooks
    # done_ratio as numeric field, done_ratio_calculation_type field
    class ViewsIssuesHook < Redmine::Hook::ViewListener
      render_on :view_issues_form_details_bottom,
                partial: 'issue_progress_hooks/view_issues_form_details_bottom'
      render_on :view_issues_context_menu_start,
                partial: 'issue_progress_hooks/view_issues_context_menu_start'
      render_on :view_issues_bulk_edit_details_bottom,
                partial: 'issue_progress_hooks/view_issues_bulk_edit_details_bottom'
    end
  end
end
