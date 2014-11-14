module QBWC
  module Response
    class SalesOrderAddRs
      attr_reader :records

      # Successfull persisted orders are given here
      def initialize(records)
        @records = records
      end

      # Move `records` here to processed folder? We can grab the order
      # by the PONumber, field current used for wombat id mapping.
      def process(config = {})
      end

      # Collection of errors. QB seems to always return one error only per
      # record. e.g.
      #
      #   For errors like this we could grab the Ref type (e.g. Item), fetch
      #   the order again in s3 so we can mount the record (Customer or Item),
      #   persist in s3 on a ready folder, next time scheduler runs the missing
      #   reference would be created and the next time after that the order
      #   might be created finally jeeeeeeeeeeeeeeeeez ... O_O I need a beer
      #
      #   - <SalesOrderAddRs statusCode="3140" statusSeverity="Error" statusMessage="There is an invalid reference to QuickBooks Item &quot;da product id 1&quot ; in the SalesOrder line.  QuickBooks error message: Invalid argument.  The specified record does not exist in the list." />
      #
      #   As far as I could see this one means a previous salesorder (in the same
      #   batch though) failed to persist. So apparently if the first one fails
      #   all the others wont even be processed.
      #
      #   - <SalesOrderAddRs statusCode="3231" statusSeverity="Error" statusMessage="The request has not been processed." />
      #
      def handle_errors(errors)
      end
    end
  end
end
