class AuthToken < ApplicationRecord
  class << self
    def token(refresh = false)
      # attempt to find cached bearer token for user unless refreshing
      auth_token = refresh ? nil : current_tokens.first

      # (re)authorize user and store new auth_token if cached auth_token has expired
      auth_token = set_new_token! unless auth_token

      auth_token.token
    end

    private

    def set_new_token!
      current_tokens.delete_all
      create! username: ApiService::API_AUTH_USER, token: ApiService.authenticate, expires_at: (Time.current + 29.days)
    end

    def current_tokens
      where(username: ApiService::API_AUTH_USER).where("expires_at > ?", Time.current)
    end
  end
end
