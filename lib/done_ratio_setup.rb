# Licensed under GNU GPL 2.0
# Author: Tecforce
# Website: http://tecforce.ru

require 'singleton'

module DoneRatioSetup
  class SettingsProxy
    include Singleton

    def []=(key, value)
      key = key.intern if key.is_a?(String)
      ActiveRecord::Base.transaction do
        if Redmine::Database.mysql?
          ActiveRecord::Base.connection.execute("LOCK TABLES #{Setting.table_name} WRITE")
        elsif Redmine::Database.postgresql?
          ActiveRecord::Base.connection.execute("LOCK TABLE #{Setting.table_name} IN ACCESS EXCLUSIVE MODE")
        end
        settings = safe_load
        settings[key] = value
        Setting.plugin_done_ratio_via_time = settings
        if Redmine::Database.mysql?
          ActiveRecord::Base.connection.execute('UNLOCK TABLES')
        end
      end
    end

    def to_h
      h = safe_load
      h.freeze
      h
    end

    private

    def safe_load
      # At the first migration, the settings table will not exist
      return {} unless Setting.table_exists?

      settings = Setting.plugin_done_ratio_via_time.dup
      if settings.is_a?(String)
        Rails.logger.error 'Unable to load settings'
        return {}
      end
      settings
    end
  end

  def setting
    SettingsProxy.instance
  end
  module_function :setting

  def settings
    SettingsProxy.instance.to_h
  end
  module_function :settings

  def default_calculation_type(project)
    if project && project.default_done_ratio_calculation_type
      project.default_done_ratio_calculation_type
    else
      settings[:global][:done_ratio_calculation_type].to_i
    end
  end
  module_function :default_calculation_type

  def time_overrun_enabled?(project)
    if project && !project.time_overrun_mode.nil?
      project.time_overrun_mode
    else
      settings[:global][:enable_time_overrun] == 'true'
    end
  end
  module_function :time_overrun_enabled?

  def block_spent_time_statuses
    IssueStatus.where(id: settings[:global][:block_spent_time_status_ids])
  end
  module_function :block_spent_time_statuses
end
