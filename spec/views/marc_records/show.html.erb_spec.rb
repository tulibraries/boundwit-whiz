require "rails_helper"

RSpec.describe "marc_records/show.html.erb", type: :view do
  it "displays MARC fields sorted by tag" do
    record = MARC::Record.new

    record.append(MARC::DataField.new("774", "0", "8"))
    record.append(MARC::ControlField.new("001", "123456"))
    record.append(MARC::DataField.new("245", "1", "0"))
    record.append(MARC::DataField.new("014", "1", " "))

    marc_record = instance_double(
      MarcRecord,
      title: "Test Record",
      record:
    )

    assign(:marc_record, marc_record)

    render

    tags = rendered.scan(/class="marc-tag">(\d{3})</).flatten
    expect(tags).to eq(%w[001 014 245 774])
  end
end
