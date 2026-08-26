module Alma
  module MarcRecordExtras
    def record
      raw_xml ||= response["anies"].first
      @record ||= MARC::XMLReader.new(StringIO.new(raw_xml)).first
    end

    def xml_headers
      { "Authorization" => "apikey #{apikey}",
        "Accept" => "application/xml",
        "Content-Type" => "application/xml" }
    end

    def apikey
      Alma.configuration.apikey
    end

    def timeout
      Alma.configuration.timeout
    end

    def bibs_base_path
      self.class.bibs_base_path
    end
  end
end
