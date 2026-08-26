require "rails_helper"

RSpec.describe Alma::Bib do
  class FakeBibResponse
    def initialize(data)
      @data = data
    end

    def [](key)
      @data[key]
    end
  end

  shared_context "stubbed Alma bib collection" do
    let(:response_body) do
      {
        "bib" => mms_ids.map do |id|
          {
            "mms_id" => id,
            "title" => "Test #{id}"
          }
        end,
        "total_record_count" => mms_ids.size
      }
    end

    let(:response) do
      instance_double(
        HTTParty::Response,
        code: 200,
        body: response_body.to_json
      )
    end

    before do
      allow(Alma::Net)
        .to receive(:get)
        .and_return(response)
    end
  end

  let(:mms_id) { "991234" }

  let(:marc_xml) do
    <<~XML
      <record xmlns="http://www.loc.gov/MARC21/slim">
        <leader>00000nam a2200000 a 4500</leader>
        <controlfield tag="001">#{mms_id}</controlfield>
        <datafield tag="245" ind1="1" ind2="0">
          <subfield code="a">Test title</subfield>
        </datafield>
      </record>
    XML
  end

  let(:bib_response) do
    FakeBibResponse.new(
      "mms_id" => mms_id,
      "anies" => [ marc_xml ]
    )
  end

  let(:bib) { described_class.new(bib_response) }

  describe "overrides" do
    it "prepends BibOverrides" do
      expect(described_class.ancestors)
        .to include(Alma::BibOverrides)
    end

    it "includes MarcRecordExtras through BibOverrides" do
      expect(Alma::BibOverrides.ancestors)
        .to include(Alma::MarcRecordExtras)
    end

    it "uses the overridden update! method" do
      expect(described_class.instance_method(:update!).owner)
        .to eq(Alma::BibOverrides)
    end

    it "uses MarcRecordExtras for record" do
      expect(described_class.instance_method(:record).owner)
        .to eq(Alma::MarcRecordExtras)
    end
  end

  describe "#holding_ids" do
    it "returns the holding ids" do
      allow(bib).to receive(:holdings).and_return(
        "holding" => [
          { "holding_id" => "123" },
          { "holding_id" => "456" }
        ]
      )

      expect(bib.holding_ids).to eq(%w[123 456])
    end
  end

  describe "#update!" do
    before do
      allow(described_class)
        .to receive(:bibs_base_path)
        .and_return("/almaws/v1/bibs")

      allow(Alma.configuration)
        .to receive_messages(
          apikey: "test-api-key",
          timeout: 10
        )
    end

    it "updates the bib in Alma" do
      response = instance_double(
        HTTParty::Response,
        code: 200,
        body: "<bib>updated</bib>"
      )

      expect(Alma::Net)
        .to receive(:put)
        .with(
          "/almaws/v1/bibs/#{mms_id}",
          headers: {
            "Authorization" => "apikey test-api-key",
            "Accept" => "application/xml",
            "Content-Type" => "application/xml"
          },
          body: "<bib>#{bib.record.to_xml_string}</bib>",
          timeout: 10
        )
          .and_return(response)

        expect(bib.update!).to eq("<bib>updated</bib>")
    end

    it "raises when Alma returns an error" do
      response = instance_double(
        HTTParty::Response,
        code: 500,
        body: "Alma error"
      )

      allow(Alma::Net)
        .to receive(:put)
        .and_return(response)

      expect { bib.update! }
        .to raise_error(StandardError, "Alma error")
    end
  end

  describe "#record" do
    it "parses MARC XML" do
      record = bib.record

      expect(record).to be_a(MARC::Record)
      expect(record["001"].value).to eq(mms_id)
      expect(record["245"]["a"]).to eq("Test title")
    end

    it "memoizes the parsed MARC record" do
      expect(bib.record).to equal(bib.record)
    end
  end

  describe "#apikey" do
    it "returns the configured Alma API key" do
      allow(Alma.configuration)
        .to receive(:apikey)
        .and_return("foo")

      expect(bib.apikey).to eq("foo")
    end
  end

  describe "#timeout" do
    it "returns the configured Alma timeout" do
      allow(Alma.configuration)
        .to receive(:timeout)
        .and_return(5)

      expect(bib.timeout).to eq(5)
    end
  end

  describe "#xml_headers" do
    it "builds the Alma XML headers" do
      allow(Alma.configuration)
        .to receive(:apikey)
        .and_return("foo")

      expect(bib.xml_headers).to eq(
        {
          "Authorization" => "apikey foo",
          "Accept" => "application/xml",
          "Content-Type" => "application/xml"
        }
      )
    end
  end

  describe "#bibs_base_path" do
    it "delegates to bibs_base_path on the class" do
      url = "https://api-na.hosted.exlibrisgroup.com/almaws/v1/bibs"

      allow(described_class)
        .to receive(:bibs_base_path)
        .and_return(url)

      expect(bib.bibs_base_path).to eq(url)
    end
  end

  describe ".get_bibs with ResultSetOverrides" do
    include_context "stubbed Alma bib collection"

    let(:mms_ids) do
      %w[
        991039535820903811
        991039535820803811
        991039535820703811
      ]
    end

    it "returns a result set that can be mapped correctly" do
      result = described_class.get_bibs(mms_ids)

      expect(result.class.ancestors)
        .to include(Alma::ResultSetOverrides)

      expect(result.map(&:id)).to eq(mms_ids)
    end

    it "supports nested mapping over the returned result set" do
      result = described_class.get_bibs(mms_ids)

      nested = result.map do |record|
        [ record.id, record.id.length ]
      end

      expect(nested).to eq(
        mms_ids.map { |id| [ id, id.length ] }
      )
    end
  end

  describe "#title" do
    it "gets the title from the record" do
      expect(bib.title).to eq("Test title")
    end
  end

  describe "#each" do
    include_context "stubbed Alma bib collection"

    let(:mms_ids) do
      %w[
        991039535820903811
        991039535820803811
        991039535820703811
      ]
    end

    it "yields each item exactly once" do
      result = described_class.get_bibs(mms_ids)

      yielded_ids = []

      result.each do |record|
        yielded_ids << record.id
      end

      expect(yielded_ids).to eq(mms_ids)
    end

    it "does not apply the block multiple times per item" do
      result = described_class.get_bibs(mms_ids)

      counts = Hash.new(0)

      result.each do |record|
        counts[record.id] += 1
      end

      expect(counts).to eq(
        mms_ids.to_h { |id| [ id, 1 ] }
      )
    end

    it "maps each item exactly once" do
      result = described_class.get_bibs(mms_ids)

      calls = Hash.new(0)

      mapped = result.map do |record|
        calls[record.id] += 1
        record.id
      end

      expect(mapped).to eq(mms_ids)

      expect(calls).to eq(
        mms_ids.to_h { |id| [ id, 1 ] }
      )
    end
  end
end
