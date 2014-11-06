module QBWC
  module Response
    class ItemInventoryAddRs
      attr_reader :result

      def initialize(result)
        @result = result
      end

      def process
      end
    end
  end
end
