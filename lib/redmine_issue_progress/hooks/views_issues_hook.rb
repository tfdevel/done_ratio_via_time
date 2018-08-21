module RedmineIssueProgress
  module Hooks
    # done_ratio as numeric field, done_ratio_calculation_type field
    class ViewsIssuesHook < Redmine::Hook::ViewListener
      render_on :view_issues_form_details_bottom,
                partial: 'hooks/view_issues_form_details_bottom'
    end
  end
end
