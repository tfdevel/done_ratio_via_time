# Licensed under GNU GPL 2.0
# Author: Tecforce
# Website: http://tecforce.ru

class AddTimeOverrunModeToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :time_overrun_mode, :boolean
  end
end
