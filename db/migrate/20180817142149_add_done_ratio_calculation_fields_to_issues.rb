class AddDoneRatioCalculationFieldsToIssues < ActiveRecord::Migration
  def change
    add_column :issues, :done_ratio_calculation_type, :integer, default: 0,
                                                                null: false

    add_index :issues, :done_ratio_calculation_type
  end
end
