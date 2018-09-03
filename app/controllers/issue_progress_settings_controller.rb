class IssueProgressSettingsController < ApplicationController
  before_action :require_admin
  before_action :check_mode_change, only: :update

  def edit
    @settings = IssueProgressSetup.settings[:global]
  end

  def update
    IssueProgressSetup.setting[:global] = settings_params
    flash[:notice] = l(:notice_successful_update)
    redirect_to action: :edit
  end

  private

  def settings_params
    params.require(:settings).permit(:done_ratio_calculation_type,
                                     :enable_time_overrun)
  end

  def check_mode_change
    new_done_ratio_calculation_type =
      settings_params[:done_ratio_calculation_type]
    if new_done_ratio_calculation_type.present? &&
       IssueProgressSetup.settings[:global][:done_ratio_calculation_type] !=
       new_done_ratio_calculation_type
      job_id = IssueDoneRatioRecalculationWorker.perform_async
      IssueProgressSetup.setting[:job_id] = job_id
    end
  end
end
