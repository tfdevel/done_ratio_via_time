class AddDefaultDoneRatioCalculationTypeToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :default_done_ratio_calculation_type, :integer
  end
end
