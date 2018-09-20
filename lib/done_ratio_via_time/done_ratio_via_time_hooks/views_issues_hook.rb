# Copyright (C) 2018 Tecforce - All rights reserved.

# This file is part of “Done ration via time plugin”.

# “Done ration via time plugin” or its sources can not be copied and/or
# distributed without the express permission of Tecforce. Unauthorized copying
# of this file, via any media, is strictly prohibited.

# Proprietary and confidential.
# For more details please contact sales@tecforce.ru.

module DoneRatioViaTime
  module Hooks
    # done_ratio as numeric field, done_ratio_calculation_type field
    class ViewsIssuesHook < Redmine::Hook::ViewListener
      render_on :view_issues_form_details_bottom,
                partial: 'done_ratio_via_time_hooks/view_issues_form_details_bottom'
      render_on :view_issues_context_menu_start,
                partial: 'done_ratio_via_time_hooks/view_issues_context_menu_start'
      render_on :view_issues_bulk_edit_details_bottom,
                partial: 'done_ratio_via_time_hooks/view_issues_bulk_edit_details_bottom'
    end
  end
end
