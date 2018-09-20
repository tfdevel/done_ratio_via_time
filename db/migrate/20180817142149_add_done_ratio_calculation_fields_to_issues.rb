# Copyright (C) 2018 Tecforce - All rights reserved.

# This file is part of “Done ration via time plugin”.

# “Done ration via time plugin” or its sources can not be copied and/or
# distributed without the express permission of Tecforce. Unauthorized copying
# of this file, via any media, is strictly prohibited.

# Proprietary and confidential.
# For more details please contact sales@tecforce.ru.

class AddDoneRatioCalculationFieldsToIssues < ActiveRecord::Migration
  def change
    add_column :issues, :done_ratio_calculation_type, :integer, default: 0,
                                                                null: false

    add_index :issues, :done_ratio_calculation_type
  end
end
