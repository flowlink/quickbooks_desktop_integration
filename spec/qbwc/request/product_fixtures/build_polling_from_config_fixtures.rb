def full_expected_output(time)
  <<~XML
    <ItemInventoryQueryRq requestID="12345903">
      <MaxReturned>50</MaxReturned>
      <FromModifiedDate>#{time.iso8601}</FromModifiedDate>
    </ItemInventoryQueryRq>
    <ItemInventoryAssemblyQueryRq requestID="12345903">
      <MaxReturned>50</MaxReturned>
      <FromModifiedDate>#{time.iso8601}</FromModifiedDate>
    </ItemInventoryAssemblyQueryRq>
    <ItemNonInventoryQueryRq requestID="12345903">
      <MaxReturned>50</MaxReturned>
      <FromModifiedDate>#{time.iso8601}</FromModifiedDate>
    </ItemNonInventoryQueryRq>
    <ItemSalesTaxQueryRq requestID="12345903">
      <MaxReturned>50</MaxReturned>
      <FromModifiedDate>#{time.iso8601}</FromModifiedDate>
    </ItemSalesTaxQueryRq>
    <ItemServiceQueryRq requestID="12345903">
      <MaxReturned>50</MaxReturned>
      <FromModifiedDate>#{time.iso8601}</FromModifiedDate>
    </ItemServiceQueryRq>
    <ItemDiscountQueryRq requestID="12345903">
      <MaxReturned>50</MaxReturned>
      <FromModifiedDate>#{time.iso8601}</FromModifiedDate>
    </ItemDiscountQueryRq>
  XML
end

def partial_expected_output(time)
  <<~XML
    <ItemInventoryQueryRq requestID="12345903">
      <MaxReturned>50</MaxReturned>
      <FromModifiedDate>#{time.iso8601}</FromModifiedDate>
    </ItemInventoryQueryRq>
    <ItemSalesTaxQueryRq requestID="12345903">
      <MaxReturned>50</MaxReturned>
      <FromModifiedDate>#{time.iso8601}</FromModifiedDate>
    </ItemSalesTaxQueryRq>
    <ItemServiceQueryRq requestID="12345903">
      <MaxReturned>50</MaxReturned>
      <FromModifiedDate>#{time.iso8601}</FromModifiedDate>
    </ItemServiceQueryRq>
  XML
end

def one_expected_output(time)
  <<~XML
    <ItemServiceQueryRq requestID="12345903">
      <MaxReturned>50</MaxReturned>
      <FromModifiedDate>#{time.iso8601}</FromModifiedDate>
    </ItemServiceQueryRq>
  XML
end
