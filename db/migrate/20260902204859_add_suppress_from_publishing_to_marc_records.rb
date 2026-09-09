class AddSuppressFromPublishingToMarcRecords < ActiveRecord::Migration[8.1]
  def change
    add_column :marc_records, :suppress_from_publishing, :boolean
  end
end
