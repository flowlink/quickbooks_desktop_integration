module QBWC
  module Response
    class ItemInventoryAddRs
      attr_reader :result

      def initialize(result)
        @result = result
      end

      def process
        #Move files and create  notifications
      end
    end
  end
end
