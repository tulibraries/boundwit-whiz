module Alma
  module BibClassOverrides
    def find(ids)
      ids = ids.respond_to?(:split) ? ids.split(",") : ids

      super(ids, {})
    end
  end
end
