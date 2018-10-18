# Licensed under GNU GPL 2.0
# Author: Tecforce
# Website: http://tecforce.ru

module DoneRatioViaTime
  module Hooks
    class ViewsLayoutsHook < Redmine::Hook::ViewListener
      def view_layouts_base_html_head(context = {})
        stylesheet_link_tag(:issue_progress, plugin: 'done_ratio_via_time')
      end
    end
  end
end
