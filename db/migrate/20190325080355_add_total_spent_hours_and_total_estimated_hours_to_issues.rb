# Licensed under GNU GPL 2.0
# Author: Tecforce
# Website: http://tecforce.ru

class AddTotalSpentHoursAndTotalEstimatedHoursToIssues < ActiveRecord::Migration
  def change
    add_column :issues, :total_estimated_hours, :float, default: nil
    add_column :issues, :total_spent_hours, :float, default: nil
  end
end
