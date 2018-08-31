require 'redmine_issue_progress'

Redmine::Plugin.register :redmine_issue_progress do
  name 'Redmine Issue Progress plugin'
  author '//twinslash'
  description 'This is a plugin for Redmine'
  version '1.0.0'
  url 'http://example.com/path/to/plugin'
  author_url 'http://example.com/about'

  menu :admin_menu, :issue_progress, { controller: 'issue_progress_settings',
                                       action: 'edit' },
       caption: :label_issue_progress_section,
       html: { class: 'icon icon-package' }
  settings default: { global: { done_ratio_calculation_type: '1' },
                      job_id: nil,
                      job_successful_complete_at: nil }

  project_module :issue_progress do
    permission :view_done_ratio_calculation_type, {}
    permission :edit_done_ratio_calculation_type, job_statuses: [:index]
  end
end
