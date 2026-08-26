module Alma
  module ResultSetOverrides
    def each
      results = super

      return results.each unless block_given?

      results.each { |item| yield item }
    end
  end
end
