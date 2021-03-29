class CreateWebhooks < ActiveRecord::Migration[6.1]
  def change
    create_table :webhooks do |t|
      t.string :origin
      t.text :payload
      t.text :api_response

      t.timestamps
    end
  end
end
