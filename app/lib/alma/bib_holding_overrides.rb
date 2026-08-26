module Alma
  module BibHoldingOverrides
    include MarcRecordExtras

    def initialize(holding)
      super
      @response = @holding
      path = @response.request.path.path
      @mms_id = path[%r{/bibs/([^/]+)}, 1]
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
  end
end
