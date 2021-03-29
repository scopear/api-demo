class Webhook < ApplicationRecord
  serialize :payload, JSON, default: {}
  serialize :api_response, JSON, default: {}
end
