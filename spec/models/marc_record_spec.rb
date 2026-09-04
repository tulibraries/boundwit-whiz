require "rails_helper"

RSpec.describe MarcRecord, type: :model do
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

  describe "#to_alma" do
    let(:marc_xml) do
      <<~XML
      <record xmlns="http://www.loc.gov/MARC21/slim">
        <leader>00000nam a2200000 i 4500</leader>
        <controlfield tag="001">991234</controlfield>
      </record>
      XML
    end

    context "when record_type is bib" do
      it "returns an Alma::Bib" do
        record = described_class.create!(
          record_type: "bib",
          record_id: "991234",
          mms_id: "991234",
          marc_xml:
        )

        expect(record.to_alma).to be_a(Alma::Bib)
      end

      it "sets the bib MMS ID" do
        record = described_class.create!(
          record_type: "bib",
          record_id: "991234",
          mms_id: "991234",
          marc_xml:
        )

        expect(record.to_alma.id).to eq("991234")
      end

      it "restores the cached MARC record" do
        record = described_class.create!(
          record_type: "bib",
          record_id: "991234",
          mms_id: "991234",
          marc_xml:
        )

        bib = record.to_alma

        expect(bib.record["001"].value).to eq("991234")
      end
    end

    context "when record_type is holding" do
      it "returns an Alma::BibHolding" do
        record = described_class.create!(
          record_type: "holding",
          record_id: "227741",
          mms_id: "991234",
          marc_xml:
        )

        expect(record.to_alma).to be_a(Alma::BibHolding)
      end

      it "sets the holding and MMS IDs" do
        record = described_class.create!(
          record_type: "holding",
          record_id: "227741",
          mms_id: "991234",
          marc_xml:
        )

        holding = record.to_alma

        expect(holding.holding_id).to eq("227741")
        expect(holding.mms_id).to eq("991234")
      end

      it "restores the cached MARC record" do
        record = described_class.create!(
          record_type: "holding",
          record_id: "227741",
          mms_id: "991234",
          marc_xml:
        )

        holding = record.to_alma
        expect(holding.record["001"].value).to eq("991234")
      end
    end

    context "when record_type is unknown" do
      it "raises an ArgumentError" do
        record = described_class.new(
          record_type: "something_else",
          record_id: "123",
          mms_id: "123",
          marc_xml:
        )

        expect {
          record.to_alma
        }.to raise_error(
          ArgumentError,
          "Unknown record type: something_else"
        )
      end
    end
  end
end
