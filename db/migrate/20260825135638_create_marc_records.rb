class CreateMarcRecords < ActiveRecord::Migration[8.1]
  def change
    create_table :marc_records do |t|
      t.string :record_id
      t.string :record_type
      t.string :title
      t.text :marc_xml

      t.timestamps
    end

    add_index :marc_records,
      [ :record_type, :record_id ],
      unique: true
  end
end
