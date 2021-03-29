class AddGqlFetchedAtToWebhooks < ActiveRecord::Migration[6.1]
  def change
    add_column :webhooks, :gql_fetched_at, :datetime
  end
end
