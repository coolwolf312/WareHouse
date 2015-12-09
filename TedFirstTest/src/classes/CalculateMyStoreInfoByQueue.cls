public class CalculateMyStoreInfoByQueue implements Queueable {
    public void execute(QueueableContext context) {
        
         List<GYProduct__c> scope =[SELECT Name,ProductType__c,unit_price__c,
                                        TotalInstore__c,(select  StoredProductNumber__c from GYS_P_Item__r) 
                                        saleOutNum__c,(select ProductSoldNumber__c from GYP_O_Item__r),
                                        purInNum__c,(select  TotalNumber__c from InProducts__r)
                                        from GYProduct__c];

      List<GYProduct__c> productInfoNeedUpdate = new List<GYProduct__c>();                                 

      for(GYProduct__c singleProduct : scope){ 
           List<GYS_P_Item__c> productsInStore = singleProduct.GYS_P_Item__r;
           decimal numInstore = 0;
           if(productsInStore!=null && productsInStore.size()>0){
              for(GYS_P_Item__c item : productsInStore){
                  numInstore = numInstore + item.StoredProductNumber__c;

              }
              singleProduct.TotalInstore__c = numInstore;
           }  

          List<GYP_O_Item__c> productsSellOut = singleProduct.GYP_O_Item__r;
          decimal numsellOut = 0;
           if(productsSellOut!=null && productsSellOut.size()>0){
              for(GYP_O_Item__c item : productsSellOut){
                  numsellOut = numsellOut + item.ProductSoldNumber__c;

              }
              singleProduct.saleOutNum__c = numsellOut;
           }  


        List<InProductItem__c> productsPurIn = singleProduct.InProducts__r;
          decimal numPurin = 0;
           if(productsPurIn!=null && productsPurIn.size()>0){
              for(InProductItem__c item : productsPurIn){
                  numPurin = numPurin + item.TotalNumber__c;

              }
              singleProduct.purInNum__c = numPurin;
           }  

          //String name = singleProduct.name;
          //system.debug(name + ' in s ' + singleProduct.TotalInstore__c  + '  out is ' + singleProduct.saleOutNum__c  + ' pur in is ' + singleProduct.purInNum__c);
        productInfoNeedUpdate.add(singleProduct);

       } 
       update productInfoNeedUpdate; 
          
           
            
             
    }
}