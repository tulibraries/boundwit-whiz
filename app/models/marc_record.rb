class MarcRecord < ApplicationRecord
  validates :record_id, presence: true
  validates :record_type, presence: true
  validates :record_id, uniqueness: { scope: :record_type }

  def refresh_from_alma!
    alma_record =
      case record_type
      when "bib"
        Alma::Bib.find(mms_id)
      when "holding"
        Alma::BibHolding.find(
          mms_id:,
          holding_id: record_id
        )
      else
        raise ArgumentError, "Unknown record type: #{record_type}"
      end

    update!(
      title: alma_record.title,
      marc_xml: alma_record.record.to_xml_string
    )

    self
  end

  def record
    @record ||= MARC::XMLReader
      .new(StringIO.new(marc_xml))
      .first
  end
end
