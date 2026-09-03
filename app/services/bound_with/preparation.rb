module BoundWith
  class NoHoldingsError < StandardError; end

  class Preparation
    attr_reader :mms_ids, :holdings, :bibs

    def initialize(mms_ids:)
      @mms_ids = mms_ids
    end

    def call
      # mapping uniq because for some reason duplicates appear
      # TODO: figure out where duplicates come from.
      @bibs = Alma::Bib.get_bibs(mms_ids).to_a.uniq(&:id)

      parent_bib = bibs.first
      @holdings = parent_bib.holdings

      raise BoundWith::NoHoldingsError if holdings.empty?

      bibs.each(&:cache!)

      if !holding_selection_required?
        
        holding_id = parent_bib.holding_ids.first

        @holding = Alma::BibHolding.find(
          mms_id: parent_bib.id,
          holding_id:
        )

        @holding.cache!
      end

      self
    end

    def holding_selection_required?
      holdings.count > 1
    end

  end
end
