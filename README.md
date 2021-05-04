# About

  This Scope AR API-Demo-Ruby is a simple Ruby-On-Rails client application that demonstrates a complete, end-to-end integration with Scope AR APIs.

  It:

  * Generates a unique deeplink that can be clicked to open the Worklink app on a mobile device and start a ScenarioSession.
  * Simulates API requests typically made by the Worklink app to create ScenarioSessions (provided as an alternative to installing the Worklink app).
  * Listens for webhook notifications pertaining to the creation/update of ScenarioSessions on Scope API servers.
  * Queries Scope GraphQL APIs for information about the ScenarioSessions identified in webhooks received.
  * Saves and displays all information received from both the API and GraphQL.

# Important Files

  * [app/controllers/webhooks_controller.rb](/tree/develop/app/controllers/webhooks_controller.rb)
  * [app/jobs/get_resource_info_job.rb](/tree/develop/app/jobs/get_resource_info_job.rb)
  * [app/models/auth_token.rb](/tree/develop/app/models/auth_token.rb)
  * [app/services/api_service.rb](/tree/develop/app/services/api_service.rb)
  * [config/credentials.yml.enc](/tree/develop/config/credentials.yml.enc)

# System dependencies

  Required:
  * Ruby (SEE: `/.ruby-version`)

  Optional:
    * RVM (SEE: `/.ruby-gemset`)
    * Scope Worklink Application installed on a mobile device
    * Static IP or Domain (See "Setup" Section)

# Setup

  Local API Server (i.e. Development Mode):

    1. Clone this repo
    2. Configure client & server applications (SEE "Client Configuration" & "Server Configuration" Sections)
    3. Run `rails db:setup`
    4. Run `rails s -p 3031` (NOTE: any non-standard port suffices to prevent conflicts with local API server)
    5. Open a browser to http://localhost:3031

  Remote API Server:

    1. Clone this repo
    2. Configure client & server applications (SEE "Client Configuration" & "Server Configuration" Sections)
    3. Run `rails db:setup`
    4. Run `rails s`
    5. Open a browser to http://your.custom.ip.or.domain

# Client Configuration

  Run `rails credentials:edit` to configure this application.

  The encrypted crendentials file includes two sets of default values which can be used 'as is' to run the application \
  against either: a) an instance of the API server running on localhost, b) Scope AR's production cloud servers.

  Comment out the "other" set of values (as indicated in the file to use either of the default configurations.
  Contact api.support@scopear.com to use a custom server (or custom Organization).

  **Note #1: `config/master.key` is atypically checked into source control so that you can easily decrypt and edit the credentials file.**
  **Note #2: the local development option requires additional steps to be performed on the API server (see "Server Configuration").**

# Server Configuration

## Local API Server

  Run the following commands in the [`api` repo directory](https://github.com/scopear/api) (assuming you have already setup the server):

  1. `bundle exec rails c`
  2. `c = Company.create permalink: 'api-demo-ruby', webhook: 'http://docker.for.mac.localhost:3031/webhooks/receive')`
  3. `a = User.create(username: 'api.demo.ruby.admin', password: '<INSERT>', scope_admin: true)`

  Then sign in as the scope admin and perform the following steps via the CMS interface:

  4. Enable reporting_admin feature flag for the organization
  5. Create a scenario (you'll need to obtain and upload a valid ar_content ".scope" file)
  6. Create a scenario catalog that contains the above scenario and an external asset id = 42 (can be any arbitrary value that you want)
  7. Create a user for the organization with worklink_viewer license and reporting_admin feature

  Then uncomment the local configuration section of the credentials file in the [`api-demo-ruby` repo directory](https://github.com/scopear/api-demo-ruby), and set the following values:

  * `api_auth_password` should match the value used in step #3
  * `ar_content_id` should match the id of the result in step #5 above (See "Retreiving the ARContentID" section below)
  * `asset_id` should match the value used in step #6 above

## Remote API Server

  Perform the steps listed above for local development, except as noted below:

  * Create the company using the permalink value of your choice (and set organization_permalink value accordingly in the credentials file)
  * Set the webhook value on the organization to the host & port bound to your client application (e.g. `http://your.custom.ip.or.domain/webhooks/receive`)
  * Set api_url to the custom ip or domain of your API server in the credentials file

  **NOTE: The internal steps used to create the sandbox account on scope production servers are [documented here](https://scopearcloud.atlassian.net/browse/CMS-3747).**

## Retrieving the ARContentId

  The id of the most recently created ArContent (otherwise known as ScenarioRelease in GraphQL Schema) can be obtained either by:

  * Executing the following command in rails console `ArContent.last.id`
  * or - Executing the following via GraphQL

      ```
      query {
        viewer {
          organization {
            scenarios {
              nodes {
                releases {
                  nodes {
                    id
                    databaseId
                  }
                }
              }
            }
          }
        }
      }
      ```

# Services (job queues, cache servers, search engines, etc.)

  Development Mode:
  * none

  Production Mode:
  * mysql
  * sidekiq

# Deployment instructions

  * Trigger a build by creating and pushing a tag to origin: `git tag -f 0.3.1; git push -f origin 0.3.1` <br>Note: you'll need to increment the major or minor version of most recent tag [listed here](https://github.com/scopear/api-demo-ruby/tags).
  * Restart the server (note: ask devops to put your ssh key on the server).

  ```
    ssh admin@api-demo-ruby.scopear.com
    sudo su
    cd /opt/scope/
    nano demo.yml     #--> update image values in demo.yml with new tag 2x (e.g. change scopear/docker-api-demo-ruby:0.3.0 -> scopear/docker-api-demo-ruby:0.3.1)
    docker stack rm demo     #--> run this command multiple times until you receive the response "Nothing found in stack: demo"
    docker stack deploy --compose-file demo.yml --prune --with-registry-auth demo
  ```

  <br>See [CMS deployment Jira documentation](https://scopearcloud.atlassian.net/wiki/spaces/CMS/pages/821264385/How+to+deploy+to+QA) for more information about troubleshooting.

