# Copyright (C) 2018 Tecforce - All rights reserved.

# This file is part of “Done ration via time plugin”.

# “Done ration via time plugin” or its sources can not be copied and/or
# distributed without the express permission of Tecforce. Unauthorized copying
# of this file, via any media, is strictly prohibited.

# Proprietary and confidential.
# For more details please contact sales@tecforce.ru.

get 'done_ratio_via_time_settings/edit', to: 'done_ratio_via_time_settings#edit'
post 'done_ratio_via_time_settings/update', to: 'done_ratio_via_time_settings#update'
get 'job_statuses', to: 'job_statuses#index'
