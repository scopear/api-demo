class WebhooksController < ApplicationController
  before_action :set_webhook, only: %i[ show edit update destroy ]
  # skip_before_action :verify_authenticity_token, only: :receive
  # GET /webhooks/recent or /webhooks/recent.json
  def recent
    @limit = 10
    @webhooks = Webhook.limit(@limit).order(id: :desc)
  end

  # POST /webhooks/receive or /webhooks/receive.json
  # TEST: `FactoryBot.create :work_instruction_session, company: Company.first`
  # - Company.first.update_attributes webhook: 'http://localhost:3031/webhooks/receive'
  # - try wget << ipconfig getifaddr en0 >>:3031 from inside container
  def receive
    # Step 1: save the incoming payload just in case further processing fails
    @webhook = Webhook.create(payload: payload, origin: request.remote_ip)

    # Step 2: queue a background job to process the webhook payload that was received.
    GetResourceInfoJob.perform_later @webhook

    # Step 3: respond to server sending the webhook letting it know that we received the data
    head :ok
  end

  protected
  def payload
    params.permit(:time, :event, :type).to_h.merge(data: params.require(:data).permit!.to_h)
  end
end
