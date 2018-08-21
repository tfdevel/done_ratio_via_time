class IssueProgressSettingsController < ApplicationController
  before_action :require_admin

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
    params.require(:settings).permit(:done_ratio_calculation_type)
  end
end
