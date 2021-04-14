require "rack"

class ScenarioSessionsController < ApplicationController
  # POST /scenario_sessions or /scenario_sessions.json
  def create
    ApiService.create_scenario_session(
      ar_content_id: session[:ar_content_id] || PublicController::DEFAULT_AR_CONTENT_ID,
      external_data: begin
          JSON.parse(session[:external_data].to_s)
        rescue JSON::ParserError
          PublicController::DEFAULT_EXTERNAL_DATA
        end
    )

    redirect_to controller: :public, action: :demo
  end
end
