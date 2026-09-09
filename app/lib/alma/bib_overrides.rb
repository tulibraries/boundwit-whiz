module Alma
  module BibOverrides
    include MarcRecordExtras

    def holdings
      @holdings_response ||= Alma::Net.get(
        "#{bibs_base_path}/#{id}/holdings",
        headers:,
        timeout: Alma::Bib.timeout
      )

      raise StandardError, @holdings_response.body unless @holdings_response.code == 200

      @parsed_holdings ||= JSON.parse(@holdings_response.body)
      @parsed_holdings.fetch("holding", [])
    end

    def holding_ids
      holdings.map { |holding| holding["holding_id"] }
    end

    def update!
      url = "#{bibs_base_path}/#{id}"

      response = Alma::Net.put(
        url,
        headers: xml_headers,
        body: "<bib>#{record.to_xml_string}</bib>",
        timeout:
      )

      raise StandardError, response.body unless response.code == 200

      response.body
    end

    def title
      record["245"]["a"].sub(/[\s\/:;,.]+\z/, "")
    end

    def cache!
        MarcRecord.find_or_initialize_by(
          record_type: "bib",
          record_id: id
        ).update!(
          mms_id: id,
          title: title,
          marc_xml: record.to_xml_string
        )
    end
  end
end
