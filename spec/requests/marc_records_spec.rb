require "rails_helper"

RSpec.describe "MarcRecords", type: :request do
  let!(:marc_record) do
    MarcRecord.create!(
      record_type: "bib",
      record_id: "991234",
      mms_id: "991234",
      title: "Some title",
      marc_xml: <<~XML
      <record xmlns="http://www.loc.gov/MARC21/slim">
        <leader>00000nam a2200000 a 4500</leader>
        <controlfield tag="001">991234</controlfield>
        <datafield tag="245" ind1="1" ind2="0">
          <subfield code="a">Some title</subfield>
        </datafield>
      </record>
      XML
    )
  end

  describe "GET /marc_records/:id" do
    it "returns http success" do
      get marc_record_path(marc_record)

      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /marc_records/:id/refresh" do
    it "redirects after refreshing" do
      allow_any_instance_of(MarcRecord)
        .to receive(:refresh_from_alma!)
        .and_return(marc_record)

      post refresh_marc_record_path(marc_record)

      expect(response).to redirect_to(marc_record_path(marc_record))
    end
  end
end
