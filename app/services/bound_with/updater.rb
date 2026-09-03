module BoundWith
  class Updater
    def initialize(bibs:, holding:)
      @bibs = bibs
      @parent_holding = holding
      @marc = MarcEditor.new
    end

    def call
      recs = bibs.map do |bib|
        marc.purge_old_fields(rec: bib.record)
      end

      parent, *children = recs

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
      bibs.each(&:cache!)
      parent_holding.cache!

      bibs
    end

    private

    attr_reader :bibs, :parent_holding, :marc
  end
end
