class AddIndexToMarcRecordsMmsId < ActiveRecord::Migration[8.1]
  def change
    add_index :marc_records, :mms_id
  end
end
