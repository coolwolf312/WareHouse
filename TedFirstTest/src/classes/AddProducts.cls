public class AddProducts {

    public AddProducts(ApexPages.StandardController controller) {
            
            this.products = retriveProducts();
            
            
    }
    
    public List<InProductItem__c> products{get;set;}
    


    // ApexPages.StandardSetController must be instantiated
    // for standard list controllers
    public ApexPages.StandardSetController setCon {
        get {
            if(setCon == null) {
            
            //List<GYProduct__c> gyplist = [SELECT ID, Name, unit_price__c FROM GYProduct__c order by unit_price__c];
           //setCon= new ApexPages.StandardSetController(gyplist);
            
               setCon = new ApexPages.StandardSetController(Database.getQueryLocator(
                    [SELECT ID, Name, unit_price__c FROM GYProduct__c order by unit_price__c desc limit 1000]));
                    
                  setCon.setPageSize(500);  
                    //system.debug('total size from database is ' + ((List<GYProduct__c>)setCon.getRecords()).size());
            }
            return setCon;
        }
        set;
    }
    
  

    // Initialize setCon and return a list of records
    public List<InProductItem__c> retriveProducts() {
    
        List<GYProduct__c> productList = setCon.getRecords();
        
        List<InProductItem__c> inproductItemList = new List<InProductItem__c>();
        Id inProductRecordId = ApexPages.currentPage().getParameters().get('id');
        
        for(GYProduct__c aProduct : productList){
        
            InProductItem__c needAddItem = new InProductItem__c();
            needAddItem.InProduct__c = inProductRecordId;
            needAddItem.Product__c = aProduct.id;
            inproductItemList.add(needAddItem);
        }
        
    
        return inproductItemList;
    }
    
  
    
  
    
     public Pagereference save(){
      
        List<InProductItem__c> insertList = new List<InProductItem__c>();
        for(InProductItem__c item :  this.products ){
            if(item.TotalNumber__c!=null &&item.TotalNumber__c!=0 ){
                insertList.add(item);
            }
        }
        if(insertList.size()>0){
            insert insertList;
        }
         Id inProductRecordId = ApexPages.currentPage().getParameters().get('id');
         try{
             return new Pagereference('javascript:alert(\'InProductItem(s) Successfully Saved!\');parent.window.opener.location.href=\'/'+inProductRecordId +'\';window.close();');
         }catch (Exception e){
             return new Pagereference('/'+inProductRecordId);
         }
       
        
        
        
    }
    
}