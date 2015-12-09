trigger reCalculateStoreWhenProductOutDelete on GYOrder__c(before delete){
    
    Set<Id> orderIds = new Set<Id>();
    Set<Id> storeIds = new Set<Id>(); 
    for(GYOrder__c order : trigger.old){
        orderIds.add(order.id);
        storeIds.add(order.ProductFrom__c);
    }
    
    List<GYP_O_Item__c> outProductDetails = [select GYProduct__c,GYOrder__c,ProductSoldNumber__c from GYP_O_Item__c where GYOrder__c=:orderIds ];
    
    Map<Id,List<GYP_O_Item__c>> proDetailMap = new Map<Id,List<GYP_O_Item__c>>();
    // id -- productId, orderDetail
    for(GYP_O_Item__c detail : outProductDetails){
    
    
    	 if(proDetailMap.containsKey(detail.GYProduct__c)){
    		list<GYP_O_Item__c>	soldSameproduct = proDetailMap.get(detail.GYProduct__c);  		
    	 	soldSameproduct.add(detail);
        	proDetailMap.put(detail.GYProduct__c,soldSameproduct);
    	 	
    	 }else{
    	 	list<GYP_O_Item__c>	soldSameproduct = new list<GYP_O_Item__c>();  		
    	 	soldSameproduct.add(detail);
        	proDetailMap.put(detail.GYProduct__c,soldSameproduct);
    	 	
    	 }
    
    
    }
    
    List<GYS_P_Item__c> needUpdateList = [select id,unitPrice__c,SubCost__c,StoredProductNumber__c,GYProduct__c  from GYS_P_Item__c where GYStore__c=:storeIds and GYProduct__c=: proDetailMap.keySet()];
    
    for(GYS_P_Item__c storeDetail : needUpdateList){
    
        if(proDetailMap.containsKey(storeDetail.GYProduct__c)){
        
        	decimal totalSoldNum = 0;
        	for(GYP_O_Item__c soldProdctionInfo : proDetailMap.get(storeDetail.GYProduct__c)){
        		
        		totalSoldNum = totalSoldNum + soldProdctionInfo.ProductSoldNumber__c;
        		       		
        	}
                
            storeDetail.StoredProductNumber__c = storeDetail.StoredProductNumber__c + totalSoldNum;
            storeDetail.SubCost__c = storeDetail.StoredProductNumber__c * storeDetail.unitPrice__c;
            //needUpdateList.add(storeDetail);
        }
    
    }
    
    update needUpdateList;
    

}