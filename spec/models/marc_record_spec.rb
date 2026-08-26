require "rails_helper"

RSpec.describe MarcRecord, type: :model do
  describe "#refresh_from_alma!" do
    it "refreshes a bib from Alma" do
      marc = instance_double(
        MARC::Record,
        to_xml_string: "<record>bib</record>"
      )

      alma_bib = instance_double(
        Alma::Bib,
        title: "Some title",
        record: marc
      )

      allow(Alma::Bib)
        .to receive(:find)
        .with("991234")
        .and_return(alma_bib)

      record = described_class.create!(
        record_type: "bib",
        record_id: "991234",
        mms_id: "991234",
        title: "Old title",
        marc_xml: "<record>old</record>"
      )

      expect(record.refresh_from_alma!).to eq(record)

      expect(record.reload).to have_attributes(
        title: "Some title",
        marc_xml: "<record>bib</record>"
      )
    end

    it "refreshes a holding from Alma" do
      marc = instance_double(
        MARC::Record,
        to_xml_string: "<record>holding</record>"
      )

      alma_holding = instance_double(
        Alma::BibHolding,
        title: nil,
        record: marc
      )

      allow(Alma::BibHolding)
        .to receive(:find)
        .with(
          mms_id: "991235",
          holding_id: "227741"
        )
        .and_return(alma_holding)

      record = described_class.create!(
        record_type: "holding",
        record_id: "227741",
        mms_id: "991235",
        marc_xml: "<record>old</record>"
      )

      record.refresh_from_alma!

      expect(record.reload).to have_attributes(
        title: nil,
        marc_xml: "<record>holding</record>"
      )
    end

    it "raises for an unknown record type" do
      record = described_class.new(
        record_type: "something_else",
        record_id: "123",
        mms_id: "123"
      )

      expect {
        record.refresh_from_alma!
      }.to raise_error(ArgumentError, /Unknown record type/)
    end
  end

  describe "#record" do
      it "parses xml back into MARC" do
        record = described_class.create!(
          record_type: "holding",
          record_id: "2277412",
          mms_id: "9912341",
          marc_xml: "<record>old</record>"
        )

        expect(record.record.fields).to eq([])
      end
  end
end
