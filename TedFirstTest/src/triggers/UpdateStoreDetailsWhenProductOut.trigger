// this trigger created on daily sales detail object (GYP_O_Item__c)  -- update GYS_P_Item__c
trigger UpdateStoreDetailsWhenProductOut on GYP_O_Item__c (after insert) { 
    

    Set<Id> outProducts = new Set<Id>();

	// get the sale product's daily summary information
     for(GYP_O_Item__c myDailysalingProduct :trigger.new){
         
         outProducts.add(myDailysalingProduct.GYOrder__c);
         
     }
     
     // Map<OutProductId,OutProduct> outProducts.ProductFrom__c -- find the store
     
     // daily sales summary -- GYOrder__c
     // daily sales product record -- GYP_O_Item__c
     // information for every product in the store --- GYS_P_Item__c
     Map<Id,GYOrder__c> dailySalesSummaryMap = new Map<Id,GYOrder__c>([
        select id,ProductFrom__c from GYOrder__c where id =: outProducts
    ]);  
    
    Map<Id,List<GYP_O_Item__c>> store_OrderDetailMap = new Map<Id,List<GYP_O_Item__c>>();
    
    
    
    Set<Id> storeIdList = new Set<Id>();
    Set<Id> outProductIdList = new Set<Id>();
    Map<Id,GYProduct__c> proMap = new Map<Id,GYProduct__c>([select id,name,unit_price__c from GYProduct__c]);
    
    
    // generate the sale_orderDetailMap -- show the stroe saling which products
    for(GYP_O_Item__c myDailysalingProduct :trigger.new){
    	
    	// get which store the product come from
        Id storeId = dailySalesSummaryMap.get(myDailysalingProduct.GYOrder__c).ProductFrom__c;
        storeIdList.add(storeId);
        
        // get the product which saling out
        Id productId = myDailysalingProduct.GYProduct__c;
        outProductIdList.add(productId);
        
        if(store_OrderDetailMap.containsKey(storeId)){
            List<GYP_O_Item__c> orderDetail = store_OrderDetailMap.get(storeId);
            orderDetail.add(myDailysalingProduct);
            store_OrderDetailMap.put(storeId, orderDetail);
            
        }else{
            List<GYP_O_Item__c> orderDetail = new  List<GYP_O_Item__c>();
            orderDetail.add(myDailysalingProduct);
            store_OrderDetailMap.put(storeId, orderDetail);           
        }   
    
    }
    
    
    // product in the store, we need to update the StoredProductNumber__c for each GYProduct__c
    
    // update the store left product information 
    List<GYS_P_Item__c> storeDetails = [select id,GYProduct__c,GYStore__c,StoredProductNumber__c 
                                        from GYS_P_Item__c where GYProduct__c=:outProductIdList 
                                        and GYStore__c =:storeIdList ];
  
    
    
    
    List<GYS_P_Item__c> needUpdateStoreDetails = new List<GYS_P_Item__c>();
    
    for(GYS_P_Item__c productInStore : storeDetails){
        Id productId = productInStore.GYProduct__c;
        Id storeId = productInStore.GYStore__c;
        
        List<GYP_O_Item__c> detail = store_OrderDetailMap.get(storeId);
       
       system.debug('we are trying to match productId ' + productId);
        
        for(GYP_O_Item__c aDetail : detail){
          
            if(aDetail.GYProduct__c == productId){
                system.debug('product id ' + productId + ' match with aDetail ' + aDetail.id + ' with product id ' + aDetail.GYProduct__c);
            
                system.debug('--------------- update productInStore is ' + productInStore.id);
                productInStore.StoredProductNumber__c = productInStore.StoredProductNumber__c -aDetail.ProductSoldNumber__c;
                productInStore.SubCost__c = productInStore.StoredProductNumber__c *proMap.get(productId).unit_price__c;
                needUpdateStoreDetails.add(productInStore);
            }
        
        }

    }
    system.debug('--------------- update store size is ' + needUpdateStoreDetails.size());
    if(needUpdateStoreDetails.size()>0){
        update needUpdateStoreDetails;
    }

}