require "rack"

class ScenarioSessionsController < ApplicationController
  API_URL          = Rails.application.credentials.api_url
  API_AUTH_TOKEN   = Rails.application.credentials.api_auth_token
  HEADERS          = {
    "Authorization" => "Bearer token=#{API_AUTH_TOKEN}",
    "Content-Type" => "application/json",
    "Accept" => "application/json"
  }.freeze

  # POST /scenario_sessions or /scenario_sessions.json
  def create

    ar_content_id = session[:ar_content_id] || PublicController::DEFAULT_AR_CONTENT_ID
    external_data = begin
      JSON.parse(session[:external_data])
    rescue JSON::ParserError
      PublicController::DEFAULT_EXTERNAL_DATA
    end
    form_data = { external_data: external_data }.to_json

    Rails.logger.info "Initiating simulated scenario session create"

    uri = URI.parse(API_URL.strip.gsub(/:ar_content_id/, ar_content_id.to_s))
    request = Net::HTTP::Post.new(uri.request_uri)
    form_data = form_data
    request.body = form_data
    HEADERS.each { |k, v| request[k] = v }

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme.downcase == "https"
    response = http.request(request)

    raise "Failed to connect to API server: #{response}" unless response.code == "200"

    Rails.logger.info "Completed simulated scenario session create"

    redirect_to controller: :public, action: :demo
  end
end
