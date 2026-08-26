require "rails_helper"

RSpec.describe Alma::BibHolding do
  let(:mms_id) { "991039535820903811" }
  let(:holding_id) { "22774182580003811" }

  let(:request_path) do
    double(
      path: double(
        path: "/almaws/v1/bibs/#{mms_id}/holdings/#{holding_id}"
      )
    )
  end

  let(:holding_data) do
    {
      "holding_id" => holding_id,
      "suppress_from_publishing" => "false",
      "anies" => [ marc_xml ]
    }
  end

  let(:holding_response) do
    data = {
      "holding_id" => holding_id,
      "suppress_from_publishing" => "false",
      "anies" => [ marc_xml ]
    }

    double(
      "holding response",
      request: request_path
    ).tap do |response|
      allow(response).to receive(:[]) { |key| data[key] }
    end
  end

  let(:marc_xml) do
    <<~XML
      <record xmlns="http://www.loc.gov/MARC21/slim">
        <leader>00000ny  a2200000   4500</leader>
        <controlfield tag="001">#{holding_id}</controlfield>
        <datafield tag="852" ind1=" " ind2=" ">
          <subfield code="b">MAIN</subfield>
        </datafield>
      </record>
    XML
  end

  describe "overrides" do
    it "prepends BibHoldingOverrides" do
      expect(described_class.ancestors)
        .to include(Alma::BibHoldingOverrides)
    end

    it "includes MarcRecordExtras through BibHoldingOverrides" do
      expect(Alma::BibHoldingOverrides.ancestors)
        .to include(Alma::MarcRecordExtras)
    end
  end

  describe "#mms_id" do
    it "extracts the MMS ID from the request path" do
      holding = described_class.new(holding_response)

      expect(holding.mms_id).to eq(mms_id)
    end
  end

  describe "#title" do
    it "allows a dummy title field." do
      holding = described_class.new(holding_response)

      expect(holding.title).to be_nil
    end
  end

  describe "#id" do
    it "extracts the MMS ID from the request path" do
      holding = described_class.new(holding_response)

      expect(holding.id).to eq(holding_id)
    end
  end

  describe "#response" do
    it "returns the holding response" do
      holding = described_class.new(holding_response)

      expect(holding.response).to eq(holding_response)
    end
  end

  describe "#suppress_from_publishing" do
    it "returns suppress_from_publishing from the holding data" do
      holding = described_class.new(holding_response)

      expect(holding.suppress_from_publishing).to eq("false")
    end
  end

  describe "#record" do
    it "parses the MARC XML from the response" do
      holding = described_class.new(holding_response)

      record = holding.record

      expect(record).to be_a(MARC::Record)
      expect(record["001"].value).to eq(holding_id)
      expect(record["852"]["b"]).to eq("MAIN")
    end

    it "memoizes the parsed MARC record" do
      holding = described_class.new(holding_response)

      expect(holding.record).to equal(holding.record)
    end
  end

  describe "#apikey" do
    it "returns the configured Alma API key" do
      allow(Alma.configuration)
        .to receive(:apikey)
        .and_return("test-api-key")

      holding = described_class.new(holding_response)

      expect(holding.apikey).to eq("test-api-key")
    end
  end

  describe "#timeout" do
    it "returns the configured Alma timeout" do
      allow(Alma.configuration)
        .to receive(:timeout)
        .and_return(30)

      holding = described_class.new(holding_response)

      expect(holding.timeout).to eq(30)
    end
  end

  describe "#xml_headers" do
    it "builds Alma XML headers" do
      allow(Alma.configuration)
        .to receive(:apikey)
        .and_return("test-api-key")

      holding = described_class.new(holding_response)

      expect(holding.xml_headers).to eq(
        {
          "Authorization" => "apikey test-api-key",
          "Accept" => "application/xml",
          "Content-Type" => "application/xml"
        }
      )
    end
  end

  describe "#bibs_base_path" do
    it "delegates to Alma::BibHolding.bibs_base_path" do
      allow(described_class)
        .to receive(:bibs_base_path)
        .and_return("/almaws/v1/bibs")

      holding = described_class.new(holding_response)

      expect(holding.bibs_base_path).to eq("/almaws/v1/bibs")
    end
  end

  describe "#update!" do
    let(:holding) do
      described_class.new(holding_response)
    end

    before do
      allow(described_class)
        .to receive(:bibs_base_path)
        .and_return("/almaws/v1/bibs")

      allow(Alma.configuration)
        .to receive_messages(
          apikey: "test-api-key",
          timeout: 30
        )
    end

    it "PUTs the updated holding to Alma" do
      response = instance_double(
        HTTParty::Response,
        code: 200,
        body: "<holding>updated</holding>"
      )

      expect(Alma::Net)
        .to receive(:put)
        .with(
          "/almaws/v1/bibs/#{mms_id}/holdings/#{holding_id}",
          headers: {
            "Authorization" => "apikey test-api-key",
            "Accept" => "application/xml",
            "Content-Type" => "application/xml"
          },
          body: a_string_including(
            "<holding>",
            "<suppress_from_publishing>false</suppress_from_publishing>",
            holding.record.to_xml_string,
            "</holding>"
          ),
          timeout: 30
        )
        .and_return(response)

      expect(holding.update!).to eq("<holding>updated</holding>")
    end

    it "raises when Alma returns a non-200 response" do
      response = instance_double(
        HTTParty::Response,
        code: 500,
        body: "Alma exploded"
      )

      allow(Alma::Net)
        .to receive(:put)
        .and_return(response)

      expect { holding.update! }
        .to raise_error(StandardError, "Alma exploded")
    end
  end
end
