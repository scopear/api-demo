# frozen_string_literal: true

# This job asks the Scope GraphQL API for information about the resource identified in the webhook payload
# NOTE: you can customize the GraphQL query to ask for whatever information you want
# SEE: https://scopearcloud.atlassian.net/wiki/spaces/CMS/pages/1270513669/GraphQL+API
class GetResourceInfoJob < ApplicationJob
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
    { id: webhook.payload["data"]["resource-id"] }
  end


  queue_as :default

  def perform(webhook)
    response = if webhook.payload["data"]["resource-type"] == 'ScenarioSession'
      ApiService.query_graphql(
        query: GQL_QUERY,
        variables: self.class.variables_for(webhook)
      )
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
end
