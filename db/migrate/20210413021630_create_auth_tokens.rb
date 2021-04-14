class CreateAuthTokens < ActiveRecord::Migration[6.1]
  def change
    create_table :auth_tokens do |t|
      t.string :username
      t.string :token
      t.datetime :expires_at

      t.timestamps
    end
  end
end
