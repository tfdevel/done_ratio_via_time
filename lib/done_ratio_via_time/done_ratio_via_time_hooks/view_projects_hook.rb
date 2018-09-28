# Copyright (C) 2018 Tecforce - All rights reserved.

# This file is part of “Done ratio via time plugin”.

# “Done ratio via time plugin” or its sources can not be copied and/or
# distributed without the express permission of Tecforce. Unauthorized copying
# of this file, via any media, is strictly prohibited.

# Proprietary and confidential.
# For more details please contact sales@tecforce.ru.

module DoneRatioViaTime
  module Hooks
    # default done ratio calculation type  in project settings
    class ViewsProjectsHook < Redmine::Hook::ViewListener
      render_on :view_projects_form,
                partial: 'done_ratio_via_time_hooks/view_projects_form'
    end
  end
end
