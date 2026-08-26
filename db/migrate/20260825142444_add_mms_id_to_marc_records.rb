class AddMmsIdToMarcRecords < ActiveRecord::Migration[8.1]
  def change
    add_column :marc_records, :mms_id, :string
  end
end
