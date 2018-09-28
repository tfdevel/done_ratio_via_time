# Copyright (C) 2018 Tecforce - All rights reserved.

# This file is part of “Done ratio via time plugin”.

# “Done ratio via time plugin” or its sources can not be copied and/or
# distributed without the express permission of Tecforce. Unauthorized copying
# of this file, via any media, is strictly prohibited.

# Proprietary and confidential.
# For more details please contact sales@tecforce.ru.

class AddDefaultDoneRatioCalculationTypeToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :default_done_ratio_calculation_type, :integer
  end
end
