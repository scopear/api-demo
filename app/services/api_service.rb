class ApiService
  # The base url that you'll use for all interactions with the server
  API_URL                   = Rails.application.credentials.api_url.strip

  # The authentication credentials that you'll use to retrieve a bearer token
  API_AUTH_USER             = Rails.application.credentials.api_auth_username
  API_AUTH_PASS             = Rails.application.credentials.api_auth_password

  # The permalink of the Organization you will simulate scenario sessions with
  ORGANIZATION_PERMALINK    = Rails.application.credentials.organization_permalink

  # A 2nd authentication token you'll pass the GraphQL endpoint
  TWO_FACTOR_TOKEN          = Rails.application.credentials.two_factor_token

  # The path that you'll use to create ScenarioSessions
  API_WIS_URL               = API_URL + 'v2/ar_contents/:ar_content_id/work_instruction_sessions'

  #The url that you'll use to execute a GraphQL query against
  API_GQL_URL               = API_URL + 'v3/graphql'

  # The path that you'll use to authenticate
  API_AUTH_URL              = API_URL + 'v2/users/sign_in.json'

  HEADERS                   = {
    "Content-Type" => "application/json",
    "Accept" => "application/json"

    # 'date' => 'Tue, 13 Apr 2021 21:21:31 GMT',
    # 'content-type' => 'application/json; charset=utf-8',
    # 'x-frame-options' => 'SAMEORIGIN',
    # 'x-xss-protection' => '1; mode=block',
    # 'x-content-type-options' => 'nosniff',
    # 'x-download-options' => 'noopen',
    # 'x-permitted-cross-domain-policies' => 'none',
    # 'referrer-policy' => 'strict-origin-when-cross-origin',
    # 'x-scopear-cms-version' => '2.20.3',
    # 'etag' => 'W/"a182a3ee742db28d5688a83da5cb9511"',
    # 'cache-control' => 'max-age=0, private, must-revalidate',
    # 'x-request-id' => '5e14c3df-1344-4907-b06a-343b0a864e25',
    # 'x-runtime' => '0.501648',
    # 'vary' => 'Accept-Encoding, Origin',
    # 'strict-transport-security' => 'max-age=31536000; includeSubDomains',

    # 'X-Frame-Options' => 'SAMEORIGIN',
    # 'X-XSS-Protection' => '1; mode=block',
    # 'X-Content-Type-Options' => 'nosniff',
    # 'X-Download-Options' => 'noopen',
    # 'X-Permitted-Cross-Domain-Policies' => 'none',
    # 'Referrer-Policy' => 'strict-origin-when-cross-origin',
    # 'X-ScopeAR-CMS-Version' => '20210413220246',
    # 'Content-Type' => 'application/json; charset=utf-8',
    # 'Cache-Control' => 'no-store, must-revalidate, private, max-age=0',
    # 'X-Request-Id' => '98c06181-5d01-47c0-8e4c-8e8b243d69b4',
    # 'X-Runtime' => '0.428402',
    # 'Vary' => 'Accept-Encoding, Origin',
    # 'X-MiniProfiler-Original-Cache-Control' => 'max-age=0, private, must-revalidate',
    # 'X-MiniProfiler-Ids' => 'pkmtpqum8pgmxq4w8ajc,60y8jf6bahok3bo135wp,qs4msm1sp4r2qm8txfl2,czf9o9lnjw7r0sfusrzh,wjdgf3ioctq7wulmkaiq,gccyv6pfhvttd1sxoxo3,mnq6caa2b02f4p3blagq,xqu2hd2ghgn5dabei7o1,ofi2is6ql2hdqxi324pw,hu1kq8vp94urf34tispv,yxiorduxvmy50mszfk96,e12yt19pwwxe4rsgrm1i,w2din111wa204hfn9tsv',
    # 'Set-Cookie' => '__profilin=p%3Dt; path=/; HttpOnly; SameSite=Lax',
    # 'Transfer-Encoding' => 'chunked',
  }.freeze


  class << self
    def authenticate
      log('authenticate') do
        try_once(
          uri: URI.parse(API_AUTH_URL),
          form_data: {
            user: {
              username: API_AUTH_USER,
              password: API_AUTH_PASS
            }
          }.to_json
        )
      end.dig("auth_token")
    end

    def create_scenario_session(ar_content_id:, external_data:)
      log('create scenario session') do
        try_twice(
          uri: URI.parse(API_WIS_URL.gsub(/:ar_content_id/, ar_content_id.to_s)),
          form_data: {
            external_data: external_data
          }.to_json
        )
      end
    end

    def query_graphql(query:, variables:)
      log('query graphql') do
        try_twice(
          uri: URI.parse(API_GQL_URL),
          form_data: {
            permalink: ORGANIZATION_PERMALINK,
            query: query,
            variables: variables
          }.to_json,
          headers: HEADERS.merge("PrivateAccessCode" => "Token token=#{TWO_FACTOR_TOKEN}")
        )
      end
    end

    private

    def log(service_name)
      Rails.logger.info "Initiating #{service_name}."

      response = yield

      raise "Failed to #{service_name}: #{response}." unless response.code == "200"

      Rails.logger.info "Completed #{service_name}."

      JSON.parse(response.body)
    end

    def try_twice(uri:, form_data:, headers: HEADERS)
      response = try_once(uri: uri, form_data: form_data, headers: headers, token: AuthToken.token)

      # refresh token and try again if 1st attempt fails because cached bearer token is invalid
      if response.code == "401"
        response = try_once(uri: uri, form_data: form_data, headers: headers, token: AuthToken.token(true))
      end

      response
    end

    def try_once(uri:, form_data:, headers: HEADERS, token: nil)
      request = Net::HTTP::Post.new(uri.request_uri)
      request.body = form_data
      headers.each { |k, v| request[k] = v }
      request["Authorization"] = "Bearer token=#{token}" unless token.nil?

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme.downcase == "https"
      http.request(request)
    end
  end
end
