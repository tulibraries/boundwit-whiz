module BoundWith
  class Updater
    def initialize(mms_ids:)
      @mms_ids = mms_ids
      @marc = MarcEditor.new
    end

    def call
      # mapping uniq because for some reason duplicates appear
      # TODO: figure out where duplicates come from.
      bibs = Alma::Bib.get_bibs(mms_ids).to_a.uniq(&:id)

      recs = bibs.map do |bib|
        marc.purge_old_fields(rec: bib.record)
      end

      parent, *children = recs

      parent_bib = bibs.first
      holding_id = parent_bib.holding_ids.first

      parent_holding = Alma::BibHolding.find(
        mms_id: parent_bib.id,
        holding_id:
      )

      holding_record = marc.purge_old_fields(
        rec: parent_holding.record
      )

      marc.add_501_field(rec: parent, recs:)

      children.each do |child|
        marc.add_773_field(parent:, child:)
        marc.add_774_field(parent:, child:)
        marc.add_501_field(rec: child, recs:)
        marc.add_014_field(parent: holding_record, child:)
      end

      bibs.each(&:update!)
      parent_holding.update!

      # cache the successfully uppdated records locally
      cache_bibs!(bibs)
      cache_holding!(parent_holding, parent_bib)

      bibs
    end

    private

    attr_reader :mms_ids, :marc


    def cache_bibs!(bibs)
      bibs.each do |bib|
        MarcRecord.find_or_initialize_by(
          record_type: "bib",
          record_id: bib.id
        ).update!(
          mms_id: bib.id,
          title: bib.title,
          marc_xml: bib.record.to_xml_string
        )
      end
    end

    def cache_holding!(holding, bib)
      MarcRecord.find_or_initialize_by(
        record_type: "holding",
        record_id: holding.id
      ).update!(
        mms_id: bib.id,
        title: holding.title,
        marc_xml: holding.record.to_xml_string
      )
    end
  end
end
