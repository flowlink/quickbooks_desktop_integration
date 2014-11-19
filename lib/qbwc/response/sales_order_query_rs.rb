module QBWC
  module Response
    class SalesOrderQueryRs
      def initialize(records)
        @records = records
      end

      def handle_error(errors, config)
        errors.each do |error|
          Persistence::Object.handle_error(config,
                                           error.merge({context: 'Querying Orders'}),
                                           "orders",
                                           error[:request_id])
        end
      end

      def process(config = {})
      end
    end
  end
end
