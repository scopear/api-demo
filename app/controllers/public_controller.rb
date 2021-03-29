class PublicController < ApplicationController
  DEFAULT_EXTERNAL_DATA = {
    anything: "you_want",
    even: {
      deeply: {
        nested: "arguments"
      }
    }
  }
  DEFAULT_AR_CONTENT_ID = Rails.application.credentials.ar_content_id
  DEFAULT_ASSET_ID = Rails.application.credentials.asset_id

  def index
  end

  def demo
    @asset_id = session[:asset_id] || DEFAULT_ASSET_ID
    @ar_content_id = session[:ar_content_id] || DEFAULT_AR_CONTENT_ID
    @external_data = session[:external_data] || JSON.pretty_generate(DEFAULT_EXTERNAL_DATA)
  end

  def save_configuration
    session[:asset_id] = params[:asset_id]
    session[:ar_content_id] = params[:ar_content_id]
    session[:external_data] = params[:external_data]

    head :ok
  end

  def reset_configuration
    session[:asset_id] = nil
    session[:ar_content_id] = nil
    session[:external_data] = nil

    redirect_to :demo
  end
end
