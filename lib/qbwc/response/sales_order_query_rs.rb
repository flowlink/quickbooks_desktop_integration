module QBWC
  module Response
    class SalesOrderQueryRs
      def initialize(records)
        @records = records
      end

      def handle_error(errors, config)

      end

      def process(config = {})
      end
    end
  end
end
