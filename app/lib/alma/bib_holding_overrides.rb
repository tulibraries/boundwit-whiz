module Alma
  module BibHoldingOverrides
    include MarcRecordExtras

    def initialize(holding)
      super
      @response = @holding
      @mms_id =
        holding["mms_id"] ||
        response.request.path.path[%r{/bibs/([^/]+)}, 1]
    end

    # Avoids throwing error when using marc_record.title, and marc_record.id
    def title
    end

    def id
      holding_id
    end

    def response
      @response
    end

    def mms_id
      @mms_id
    end


    def update!
      url = "#{bibs_base_path}/#{mms_id}/holdings/#{holding_id}"

      response = Alma::Net.put(
        url,
        headers: xml_headers,
        body: "<holding>
      <suppress_from_publishing>#{suppress_from_publishing}</suppress_from_publishing>
      #{record.to_xml_string}
      </holding>",
      timeout:
      )

      raise StandardError, response.body unless response.code == 200

      response.body
    end

    def suppress_from_publishing
      @holding["suppress_from_publishing"]
    end

    def cache!
      MarcRecord.find_or_initialize_by(
        record_type: "holding",
        record_id: id
      ).update!(
        mms_id: mms_id,
        title: title,
        marc_xml: record.to_xml_string,
        suppress_from_publishing: suppress_from_publishing
      )
    end
  end
end
