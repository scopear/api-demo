# frozen_string_literal: true

# This job asks the Scope GraphQL API for information about the resource identified in the webhook payload
# NOTE: you can customize the GraphQL query to ask for whatever information you want
# SEE: https://scopearcloud.atlassian.net/wiki/spaces/CMS/pages/1270513669/GraphQL+API
class GetResourceInfoJob < ApplicationJob
  GQL_URL = Rails.application.credentials.gql_url
  API_AUTH_TOKEN = Rails.application.credentials.api_auth_token
  TWO_FACTOR_TOKEN = Rails.application.credentials.two_factor_token
  ORGANIZATION_PERMALINK = Rails.application.credentials.organization_permalink
  HEADERS = {
    "Authorization" => "Token token=#{API_AUTH_TOKEN}",
    "PrivateAccessCode" => "Token token=#{TWO_FACTOR_TOKEN}",
    "Content-Type" => "application/json",
    "Accept" => "application/json"
  }.freeze

  # SEE: https://scopearcloud.atlassian.net/wiki/spaces/CMS/pages/1286799365/Session+Data+Sample+Query
#      node(id: "VBi2Un82k7dJkCcGprUEj2V5KeWpBxH72XoOoiPKlbdpKLMxEQ1qtnC40gm8LzRT") {
  GQL_QUERY = <<~GQL
    query SampleScenarioSessionNodeQueryDemonstratingImportantFields($id: ID!) {
      node(id: $id) {
        ... on ScenarioSession {
          startedAt
          endedAt
          duration
          idleDuration
          numberOfStepsPossible
          numberOfStepsViewed
          percentOfStepsViewed
          state
          externalData # NOTE: this is where the data passed from the System of Record can be found
          scenarioRelease {
            author {
              id
              name
            }
            publishedAt
            scenario {
              author {
                id
                name
              }
              description
              name
              originGroup {
                id
                name
              }
              publishedAt
            }
            type
            version
          }
          events {
            nodes {
              id
              createdAt
              receivedAt
              type
              externalData
            }
          }
          steps {
            nodes {
              scenarioStep {
                name
                orderIndex
                scenarioSequence {
                  name
                }
              }
            }
          }
        }
      }
    }
  GQL

  def self.variables_for(webhook)
    {
      id: webhook.payload["data"]["resource-id"]
    }
  end

  queue_as :default

  def perform(webhook)
    resource_type = webhook.payload["data"]["resource-type"]
    response = if resource_type == 'ScenarioSession'
      variables = self.class.variables_for(webhook)
      query_api(GQL_QUERY, variables)
    else
      {
        "!!!Payload Ignored!!!" => 'This application is currently configured to only process webhooks with resource-type of ScenarioSession'
      }
    end

    webhook.update!(gql_fetched_at: Time.current, api_response: response)

    # raising after saving response so that job can be retried (if configured to be retriable)
    raise "Failed to execute GraphQL Query for webhook: #{webhook.id}" unless response["errors"].blank?

    # NOTE: This is the first opportunity to do something specific based on the scenario session data
    # .e.g. initiate call to system of record if response["data"]["externalData"] != ""
  end

  def query_api(query, variables = {})
    Rails.logger.info "Initiating GraphQL Query"

    form_data = { #URI.encode_www_form({
      permalink: ORGANIZATION_PERMALINK,
      query: query,
      variables: variables
    }.to_json

    uri = URI.parse(GQL_URL.strip)
    request = Net::HTTP::Post.new(uri.request_uri)
    request.body = form_data
    HEADERS.each { |k, v| request[k] = v }

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme.downcase == "https"
    response = http.request(request)

    raise "Failed to execute GraphQL query: #{response}" unless response.code == "200"

    Rails.logger.info "Completed GraphQL Query"

    JSON.parse(response.body)
  end
end
