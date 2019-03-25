class AddTotalSpentHoursAndTotalEstimatedHoursToIssues < ActiveRecord::Migration
  def change
    add_column :issues, :total_estimated_hours, :float, default: 0
    add_column :issues, :total_spent_hours, :float, default: 0
  end
end
