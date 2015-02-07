trigger UpdateStoreDetailsWhenProductIn on InProductItem__c (before insert,before update,before delete) {
  
    Set<Id> inProductIdSet = new  Set<Id>();
     for(InProductItem__c newCreatedInProductDetail :trigger.new){
         
         inProductIdSet.add(newCreatedInProductDetail.InProduct__c);
         
     }
    
    Map<Id,InProduct__c> productStroeMap = new Map<Id,InProduct__c>([
        select id,InProductFor__c from InProduct__c where id =: inProductIdSet
    ]);  
    
    
    
    
    Set<Id> inproductIds = new Set<Id>();
    Set<Id> myStoreIds = new Set<Id>();
    Map<Id,Set<Id>> inStoreProductMap = new Map<Id,Set<Id>>();
    
    
    for(InProductItem__c newCreatedInProductDetail :trigger.new){
        Id productId = newCreatedInProductDetail.Product__c;
        Id storeId = productStroeMap.get(newCreatedInProductDetail.InProduct__c).InProductFor__c;
      
        
        inproductIds.add(productId);  
        myStoreIds.add(storeId);
        
        if(inStoreProductMap.containsKey(storeId)){
            Set<Id> productList = inStoreProductMap.get(storeId);
            productList.add(productId);
            inStoreProductMap.put(storeId, productList);
            
        }else{
             Set<Id> productList = new Set<Id>();
             productList.add(productId);
             inStoreProductMap.put(storeId, productList);
            
        }

        
    }
    
    List<GYS_P_Item__c> storeDetails = [select id,GYProduct__c,GYStore__c,StoredProductNumber__c 
                                        from GYS_P_Item__c where GYProduct__c=:inproductIds 
                                        and GYStore__c =:myStoreIds ];
    Map<Id,GYProduct__c> proMap = new Map<Id,GYProduct__c>([select id,name from GYProduct__c]);
    // there is no items in store
    
    
    // this map contains the details for every store Map<StoreId,StoreDetails>
    Map<id,List<GYS_P_Item__c>> storeDetailMap = new  Map<id,List<GYS_P_Item__c>>();
    Map<id,List<Id>> storeDetailIdMap = new  Map<id,List<Id>>();
    for(GYS_P_Item__c aStoreDetail : storeDetails){
        
        if(storeDetailMap.containsKey(aStoreDetail.GYStore__c)){
            
            List<GYS_P_Item__c>   detailList =  storeDetailMap.get(aStoreDetail.GYStore__c);
            detailList.add(aStoreDetail);
            storeDetailMap.put(aStoreDetail.GYStore__c,detailList); 
            
            List<Id>  detailIdList =  storeDetailIdMap.get(aStoreDetail.GYStore__c);
            detailIdList.add(aStoreDetail.GYProduct__c);
            storeDetailIdMap.put(aStoreDetail.GYStore__c,detailIdList);      
            
            
            
        }else{
            List<GYS_P_Item__c>   detailList = new List<GYS_P_Item__c>();
            detailList.add(aStoreDetail);
            storeDetailMap.put(aStoreDetail.GYStore__c,detailList);  
            
             List<Id>  detailIdList =  new List<Id>();
            detailIdList.add(aStoreDetail.GYProduct__c);
            storeDetailIdMap.put(aStoreDetail.GYStore__c,detailIdList);      
            
        }                        
    }
    
    // now we get every store and its store details
    // get the store we need.
    List<GYS_P_Item__c> productStoreNeedUpdateList = new List<GYS_P_Item__c>();
    List<GYS_P_Item__c> productStoreNeedCreateList = new List<GYS_P_Item__c>();
   
    for(Id storeId : myStoreIds){
        List<GYS_P_Item__c> theStoreDetails = storeDetailMap.get(storeId);
        Map<Id,GYS_P_Item__c> productMap = new Map<Id,GYS_P_Item__c>();
       
        if(theStoreDetails==null){
              theStoreDetails=new List<GYS_P_Item__c>();
        }
        for(GYS_P_Item__c productInStore :theStoreDetails ){
            productMap.put(productInStore.GYProduct__c,productInStore);
        }
      
        // already in store product list
        List<Id> productInStoreList = storeDetailIdMap.get(storeId);
        if(productInStoreList==null)
            productInStoreList = new List<Id>();
        Set<Id> productInStoreSet = new Set<Id>();
        productInStoreSet.addAll(productInStoreList);
        
        //income productList
        Set<Id> incomeProductSet = inStoreProductMap.get(storeId);
       if(trigger.isInsert){ 
        if(productInStoreSet.containsAll(incomeProductSet)){
            // store product list contains all the items we buy in this time
            // what we need is update the store details at the same time
            for(Id incomeProductId : incomeProductSet){
                // need to get all the incomeproduct details -- number and then add them into store
            }
            
            
        }else{
         // there are some new items we didn't have, need to find them and create them as new store details   
            Set <Id> productIdsNeedInsert = incomeProductSet.clone();
            productIdsNeedInsert.removeAll(productInStoreSet);
            for(Id productId :productIdsNeedInsert ){
               GYS_P_Item__c newStoreDetail = new GYS_P_Item__c();
                newStoreDetail.GYProduct__c = productId;
                System.debug('GYProduct__c is ' + productId);
                newStoreDetail.GYStore__c = storeId;
                 System.debug('GYStore__c is ' + storeId);
                newStoreDetail.Name = proMap.get(productId).name;
                 System.debug('Name is ' + proMap.get(productId).name);
                
                newStoreDetail.StoredProductNumber__c =0;
                productStoreNeedCreateList.add(newStoreDetail); 
                productMap.put(productId, newStoreDetail);
            }
            if(productStoreNeedCreateList.size()!=0){
                insert productStoreNeedCreateList;

            }
            
        }
       } 
        for(InProductItem__c newCreatedInProductDetail :trigger.new){
            
            newCreatedInProductDetail.subCost__c = newCreatedInProductDetail.TotalNumber__c * newCreatedInProductDetail.unitPrice__c;
            Id productId = newCreatedInProductDetail.Product__c;
            GYS_P_Item__c aStoreDetail = productMap.get(productId);
            System.debug('old stored is ' + aStoreDetail.StoredProductNumber__c);
            System.debug('inProduct is ' + newCreatedInProductDetail.TotalNumber__c);
           
            System.debug('new stored is ' + aStoreDetail.StoredProductNumber__c);
            
            if(trigger.isInsert){
              aStoreDetail.StoredProductNumber__c = aStoreDetail.StoredProductNumber__c + newCreatedInProductDetail.TotalNumber__c;
            }else if(trigger.isUpdate){
                if(newCreatedInProductDetail.TotalNumber__c != trigger.oldMap.get(newCreatedInProductDetail.id).TotalNumber__c){
                    aStoreDetail.StoredProductNumber__c = aStoreDetail.StoredProductNumber__c + newCreatedInProductDetail.TotalNumber__c - trigger.oldMap.get(newCreatedInProductDetail.id).TotalNumber__c;
                }
               
            }else{
                aStoreDetail.StoredProductNumber__c = aStoreDetail.StoredProductNumber__c - newCreatedInProductDetail.TotalNumber__c;
            }
            aStoreDetail.SubCost__c = aStoreDetail.StoredProductNumber__c* newCreatedInProductDetail.unitPrice__c;
            productStoreNeedUpdateList.add(aStoreDetail);
           
            
            
        }
        
        if(productStoreNeedUpdateList.size()>0){
            update productStoreNeedUpdateList;
        }
     
        
        
    }
   
}