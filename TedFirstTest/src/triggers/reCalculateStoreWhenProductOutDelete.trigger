trigger reCalculateStoreWhenProductOutDelete on GYOrder__c(before delete){
    
    Set<Id> orderIds = new Set<Id>();
    Set<Id> storeIds = new Set<Id>(); 
    for(GYOrder__c order : trigger.old){
        orderIds.add(order.id);
        storeIds.add(order.ProductFrom__c);
    }
    
    List<GYP_O_Item__c> outProductDetails = [select GYProduct__c,GYOrder__c,ProductSoldNumber__c from GYP_O_Item__c where GYOrder__c=:orderIds ];
    
    Map<Id,GYP_O_Item__c> proDetailMap = new Map<Id,GYP_O_Item__c>();
    // id -- productId, orderDetail
    for(GYP_O_Item__c detail : outProductDetails){
    
        proDetailMap.put(detail.GYProduct__c,detail);
    
    }
    
    List<GYS_P_Item__c> needUpdateList = [select id,unitPrice__c,SubCost__c,StoredProductNumber__c,GYProduct__c  from GYS_P_Item__c where GYStore__c=:storeIds and GYProduct__c=: proDetailMap.keySet()];
    
    for(GYS_P_Item__c storeDetail : needUpdateList){
    
        if(proDetailMap.containsKey(storeDetail.GYProduct__c)){
        
            storeDetail.StoredProductNumber__c = storeDetail.StoredProductNumber__c + proDetailMap.get(storeDetail.GYProduct__c).ProductSoldNumber__c;
            storeDetail.SubCost__c = storeDetail.StoredProductNumber__c * storeDetail.unitPrice__c;
        }
    
    }
    
    update needUpdateList;
    

}