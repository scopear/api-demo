class ChangeTokenToTextType < ActiveRecord::Migration[6.1]
  def change
    change_column :auth_tokens, :token, :text
  end
end
