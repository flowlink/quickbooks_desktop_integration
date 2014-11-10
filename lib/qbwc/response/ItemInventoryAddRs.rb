module QBWC
  module Response
    class ItemInventoryAddRs
      attr_reader :result

      def initialize(result)
        @result = result
      end

      def process
        # result['ItemInventoryAddRs'].values.each do |object|
          # object['ItemInventoryRet']['Name']
        # end

        nil
        #Move files and create  notifications
        # result['ItemInventoryAddRs'].values.each do ||
        # end
        # => {"ItemInventoryAddRs"=>
  # {"ItemInventoryRet"=>
    # {"ListID"=>"80000011-1415662181",
     #"TimeCreated"=>#<DateTime: 2014-11-10T21:29:41-02:00 ((2456972j,84581s,0n),-7200s,2299161j)>,
     #"TimeModified"=>#<DateTime: 2014-11-10T21:29:41-02:00 ((2456972j,84581s,0n),-7200s,2299161j)>,
     # "EditSequence"=>"1415662181",
     # "Name"=>"12154",
     # "FullName"=>"12154",
     # "IsActive"=>true,
     # "Sublevel"=>"0",
     # "SalesPrice"=>"0.00",
     # "IncomeAccountRef"=>{"ListID"=>"8000001A-1415022649", "FullName"=>"Inventory Asset"},
     # "PurchaseCost"=>"0.00",
     # "COGSAccountRef"=>{"ListID"=>"8000001A-1415022649", "FullName"=>"Inventory Asset"},
     # "AssetAccountRef"=>{"ListID"=>"8000001A-1415022649", "FullName"=>"Inventory Asset"},
     # "QuantityOnHand"=>"0",
     # "AverageCost"=>"0.00",
     # "QuantityOnOrder"=>"0",
     # "QuantityOnSalesOrder"=>"0"},
   # "@requestID"=>"SXRlbUludmVudG9yeUFkZHwxNTA=",
   # "@statusCode"=>"0",
   # "@statusSeverity"=>"Info",
   # "@statusMessage"=>"Status OK"}}
      end
    end
  end
end
