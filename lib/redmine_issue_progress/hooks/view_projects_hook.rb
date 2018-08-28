module RedmineIssueProgress
  module Hooks
    # default done ratio calculation type  in project settings
    class ViewsProjectsHook < Redmine::Hook::ViewListener
      render_on :view_projects_form, partial: 'hooks/view_projects_form'
    end
  end
end
