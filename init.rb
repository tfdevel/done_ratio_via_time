# Copyright (C) 2018 Tecforce - All rights reserved.

# This file is part of “Done ration via time plugin”.

# “Done ration via time plugin” or its sources can not be copied and/or
# distributed without the express permission of Tecforce. Unauthorized copying
# of this file, via any media, is strictly prohibited.

# Proprietary and confidential.
# For more details please contact sales@tecforce.ru.

require 'done_ratio_via_time'

Redmine::Plugin.register :done_ratio_via_time do
  name 'Done ratio via time plugin'
  author '//twinslash'
  description 'This is a plugin for Redmine'
  version '2.0.1'
  url 'https://github.com/tfdevel/done_ratio_via_time'
  author_url 'https://twinslash.com'

  menu :admin_menu, :issue_progress, { controller: 'done_ratio_via_time_settings',
                                       action: 'edit' },
       caption: :label_done_ratio_via_time_section,
       html: { class: 'icon icon-package' }
  settings default: { global: { done_ratio_calculation_type: '1' },
                      job_id: nil,
                      job_successful_complete_at: nil,
                      enable_time_overrun: nil,
                      trackers_with_disabled_manual_mode: [] }

  project_module :issue_progress do
    permission :edit_done_ratio_calculation_type, job_statuses: [:index]
  end
end
