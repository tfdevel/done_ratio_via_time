# Licensed under GNU GPL 2.0
# Author: Tecforce
# Website: http://tecforce.ru

class DoneRatioViaTimeSettingsController < ApplicationController
  before_action :require_admin

  def edit
    @settings = DoneRatioSetup.settings[:global]
  end

  def update
    new_done_ratio_calculation_type =
      settings_params[:done_ratio_calculation_type]
    if new_done_ratio_calculation_type.present? &&
       DoneRatioSetup.settings[:global][:done_ratio_calculation_type] !=
       new_done_ratio_calculation_type
      is_recalculation_required = true
    end
    DoneRatioSetup.setting[:global] = settings_params
    flash[:notice] = l(:notice_successful_update)
    if is_recalculation_required
      DoneRatioSetup.setting[:job_id] =
        IssueDoneRatioRecalculationWorker.perform_async
    end
    redirect_to action: :edit
  end

  private

  def settings_params
    params.require(:settings).permit(:done_ratio_calculation_type,
                                     :primary_assessment,
                                     :enable_time_overrun,
                                     trackers_with_disabled_manual_mode: [],
                                     statuses_for_hours_alignment: [])
  end
end
