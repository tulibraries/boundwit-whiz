class AddOmniauthFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :uid, :string
    add_column :users, :provider, :string
    add_column :users, :first_name, :string
    add_column :users, :last_name, :string

    add_index :users, :uid, unique: true
  end
end
