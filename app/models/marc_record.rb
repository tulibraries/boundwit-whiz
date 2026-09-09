class MarcRecord < ApplicationRecord
  validates :record_id, presence: true
  validates :record_type, presence: true
  validates :record_id, uniqueness: { scope: :record_type }

  def record
    @record ||= MARC::XMLReader
      .new(StringIO.new(marc_xml))
      .first
  end

  # I need a way to go from the cached record back to a bib or holding instance
  # in order to avoid having to make multiple calls to alma for the same records
  # when processing a multi step form.
  def to_alma
    case record_type
    when "bib"     then to_bib
    when "holding" then to_holding
    else
      raise ArgumentError.new("Unknown record type: #{record_type}")
    end
  end

  def to_bib
    Alma::Bib.new(
      "mms_id" => mms_id,
      "anies" => [ marc_xml ]
    )
  end

  def to_holding
    Alma::BibHolding.new(
      "mms_id" => mms_id,
      "holding_id" => record_id,
      "suppress_from_publishing" => suppress_from_publishing,
      "anies" => [ marc_xml ]
    )
  end
end
