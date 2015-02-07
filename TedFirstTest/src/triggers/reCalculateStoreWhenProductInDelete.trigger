trigger reCalculateStoreWhenProductInDelete on InProduct__c(before delete){
    
    Set<Id> orderIds = new Set<Id>();
    Set<Id> storeIds = new Set<Id>(); 
    for(InProduct__c inProduct : trigger.old){
        orderIds.add(inProduct.id);
        storeIds.add(inProduct.InProductFor__c);
    }
    
    List<InProductItem__c> inProductDetails = [select Product__c,InProduct__c,TotalNumber__c from InProductItem__c where InProduct__c=:orderIds ];
    
    Map<Id,InProductItem__c> proDetailMap = new Map<Id,InProductItem__c>();
    // id -- productId, orderDetail
    for(InProductItem__c detail : inProductDetails){
    
        proDetailMap.put(detail.Product__c,detail);
    
    }
    
    List<GYS_P_Item__c> needUpdateList = [select id,unitPrice__c,SubCost__c,StoredProductNumber__c,GYProduct__c from GYS_P_Item__c where GYStore__c=:storeIds and GYProduct__c=: proDetailMap.keySet()];
    
    for(GYS_P_Item__c storeDetail : needUpdateList){
    
        if(proDetailMap.containsKey(storeDetail.GYProduct__c)){
        
            storeDetail.StoredProductNumber__c = storeDetail.StoredProductNumber__c - proDetailMap.get(storeDetail.GYProduct__c).TotalNumber__c;
			storeDetail.SubCost__c = storeDetail.StoredProductNumber__c * storeDetail.unitPrice__c;
        }
    
    }
    
    update needUpdateList;
    

}