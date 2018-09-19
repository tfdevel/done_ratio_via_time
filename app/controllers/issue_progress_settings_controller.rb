class IssueProgressSettingsController < ApplicationController
  before_action :require_admin

  def edit
    @settings = IssueProgressSetup.settings[:global]
  end

  def update
    new_done_ratio_calculation_type =
      settings_params[:done_ratio_calculation_type]
    if new_done_ratio_calculation_type.present? &&
       IssueProgressSetup.settings[:global][:done_ratio_calculation_type] !=
       new_done_ratio_calculation_type
      is_recalculation_required = true
    end
    IssueProgressSetup.setting[:global] = settings_params
    flash[:notice] = l(:notice_successful_update)
    if is_recalculation_required
      IssueProgressSetup.setting[:job_id] =
        IssueDoneRatioRecalculationWorker.perform_async
    end
    redirect_to action: :edit
  end

  private

  def settings_params
    params.require(:settings).permit(:done_ratio_calculation_type,
                                     :enable_time_overrun,
                                     trackers_with_disabled_manual_mode: [])
  end
end
