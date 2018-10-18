# Licensed under GNU GPL 2.0
# Author: Tecforce
# Website: http://tecforce.ru

module DoneRatioViaTime
  module Hooks
    # default done ratio calculation type  in project settings
    class ViewsProjectsHook < Redmine::Hook::ViewListener
      render_on :view_projects_form,
                partial: 'done_ratio_via_time_hooks/view_projects_form'
    end
  end
end
