# Licensed under GNU GPL 2.0
# Author: Tecforce
# Website: http://tecforce.ru

require 'done_ratio_via_time'

Redmine::Plugin.register :done_ratio_via_time do
  name 'Done ratio via time plugin'
  author 'Tecforce'
  description 'This is a plugin for Redmine'
  version '1.0.0'
  url 'https://github.com/tfdevel/done_ratio_via_time'
  author_url 'http://tecforce.ru'

  menu :admin_menu, :issue_progress, { controller: 'done_ratio_via_time_settings',
                                       action: 'edit' },
       caption: :label_done_ratio_via_time_section,
       html: { class: 'icon icon-package' }
  settings default: { global: { done_ratio_calculation_type: '1',
                                enable_time_overrun: nil,
                                trackers_with_disabled_manual_mode: [],
                                statuses_for_hours_alignment: IssueStatus.where(is_closed: true)
                                                                         .pluck(:id).map(&:to_s) },
                      job_successful_complete_at: nil,
                      job_id: nil,
                      primary_assessment: nil,
                      block_spent_time_status_ids: [] },
           partial: 'done_ratio_via_time/settings'

  project_module :issue_progress do
    permission :edit_done_ratio_calculation_type, job_statuses: [:index]
  end
end
