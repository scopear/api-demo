# About

  This Scope AR API-Demo-Ruby is a simple Ruby-On-Rails client application that demonstrates a complete, end-to-end integration with Scope AR APIs.

  It:

  * Generates a unique deeplink that can be clicked to open the Worklink app on a mobile device and start a ScenarioSession.
  * Simulates API requests typically made by the Worklink app to create ScenarioSessions (provided as an alternative to installing the Worklink app).
  * Listens for webhook notifications pertaining to the creation/update of ScenarioSessions on Scope API servers.
  * Queries Scope GraphQL APIs for information about the ScenarioSessions identified in webhooks received.
  * Saves and displays all information received from both the API and GraphQL.

# Important Files

  * app/controllers/webhooks_controller.rb
  * app/jobs/get_resource_info_job.rb
  * config/credentials.yml.enc

# System dependencies

  Required:
  * Ruby (SEE: `/.ruby-version`)

  Optional:
    * RVM (SEE: `/.ruby-gemset`)
    * Scope Worklink Application installed on a mobile device
    * Static IP (or fixed Host) (See "Setup" Section)

# Setup

  Local API Server (i.e. Development Mode):

    1. Clone this repo
    2. Configure client & server applications (SEE "Client Configuration" & "Server Configuration" Sections)
    3. run `rails db:setup`
    4. run `rails s -p 3031` (NOTE: any non-standard port suffices to prevent conflicts with local API server)
    5. open a browser to http://localhost:3031

  Remote API Server:

    1. Clone this repo
    2. Configure client & server applications (SEE "Client Configuration" & "Server Configuration" Sections)
    3. run `rails db:setup`
    4. run `rails s`
    5. open a browser to http://your.custom.ip.or.domain

# Client Configuration

  Run `rails credentials:edit` to configure this application.

  The encrypted crendentials file includes two sets of default values which can be used 'as is' to run the application \
  against either: a) an instance of the API server running on localhost, b) Scope AR's production cloud servers.

  Comment out the "other" set of values (as indicated in the file to use either of the default configurations.
  Contact api.support@scopear.com to use a custom server (or custom Organization).

  **Note #1: `config/master.key` is atypically checked into source control so that you can easily decrypt and edit the credentials file.**
  **Note #2: the local development option requires additional steps to be performed on the API server (see "Server Configuration").**

# Server Configuration

  Local API Server:

    Run the following commands in the [`api` repo directory](https://github.com/scopear/api) (assuming you have already setup the server):

      1. `bundle exec rails c`
      2. > `c = Company.first`
      3. > `c.update!(webhook: 'http://docker.for.mac.localhost:3031/webhooks/receive')`
      4. > `c.permalink`
      5. > `c.ar_contents.first.id`
      6. > `c.scenario_catalogs.first_or_create(external_asset_id: "42")` #note: "42" is an arbitrary value [from "The Hitchhiker's Guide To The Galaxy] that can be changed to any value you prefer.
      7. > `c.api_key`
      8. > `GQL::TWO_FACTOR_TOKEN`

    Then set the values in the credentials file in the [`api-demo-ruby` repo directory](https://github.com/scopear/api-demo-ruby):

    * `organization_permalink` should match the value of step #4 above
    * `ar_content_id` should match the value of step #5 above
    * `asset_id` should match the value of step #6 above
    * `api_auth_token` should match the value of step #7 above
    * `two_factor_token` should match the value of step #8 above

  Remote API Server:

    Perform the steps listed above (for local development), except as follows:

    * `c = Company.first` should use something specific to your account
    * `c.update!(webhook: 'http://docker.for.mac.localhost:3031/webhooks/receive')` should use the host & port bound to this client application (e.g. `http://your.custom.ip.or.domain/webhooks/receive`)
    * `api_url` should use the url of the API server
    * `gql_url` should use the url of the GraphQL server

# Services (job queues, cache servers, search engines, etc.)

  Development Mode:
  * none

  Production Mode:
  * mysql
  * sidekiq

# Deployment instructions

  * trigger a build by creating and pushing a tag to origin: `git tag -f 0.2.1; git push -f origin 0.2.1` <br>Note: increment the major or minor version of most recent tag listed here: https://github.com/scopear/api-demo-ruby/tags.
  * restart the server (note: ask devops to put your ssh key on the server).

  ```
    ssh admin@api-demo-ruby.scopear.com
    sudo su
    cd /opt/scope/
    nano demo.yml  #-> update image values in demo.yml with new tag 2x (e.g. change scopear/docker-api-demo-ruby:0.2.0 -> scopear/docker-api-demo-ruby:0.2.1)
    docker stack rm demo  #-> run this multiple times until you receive the response "Nothing found in stack: demo"
    docker stack deploy --compose-file demo.yml --prune --with-registry-auth demo
  ```

  <br>See [CMS deployment Jira documentation](https://scopearcloud.atlassian.net/wiki/spaces/CMS/pages/821264385/How+to+deploy+to+QA) for more information about troubleshooting.

