# Copyright (C) 2018 Tecforce - All rights reserved.

# This file is part of “Done ration via time plugin”.

# “Done ration via time plugin” or its sources can not be copied and/or
# distributed without the express permission of Tecforce. Unauthorized copying
# of this file, via any media, is strictly prohibited.

# Proprietary and confidential.
# For more details please contact sales@tecforce.ru.

require 'sidekiq_initialization'

# must be loaded before IssueQuery
require 'done_ratio_via_time/patches/issue_relation_patch'

require 'done_ratio_setup'
require 'calculate_done_ratio'
require 'update_parents_done_ratio'

require 'workers/issue_done_ratio_recalculation_worker'

Rails.configuration.to_prepare do
  # patches
  require 'done_ratio_via_time/patches/issue_patch'
  require 'done_ratio_via_time/patches/time_entry_patch'
  require 'done_ratio_via_time/patches/issues_helper_patch'
  require 'done_ratio_via_time/patches/issue_relations_controller_patch'
  require 'done_ratio_via_time/patches/issue_query_patch'
  require 'done_ratio_via_time/patches/project_patch'
  require 'done_ratio_via_time/patches/enabled_module_patch'

  # hooks
  require 'done_ratio_via_time/done_ratio_via_time_hooks/views_issues_hook'
  require 'done_ratio_via_time/done_ratio_via_time_hooks/view_projects_hook'
  require 'done_ratio_via_time/done_ratio_via_time_hooks/view_layouts_hook'
end
