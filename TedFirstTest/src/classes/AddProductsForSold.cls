public class AddProductsForSold {

    public AddProductsForSold (ApexPages.StandardController controller) {
            
            this.products = retriveProducts();
            
            
    }
    
    public List<GYP_O_Item__c> products{get;set;}
    


    // ApexPages.StandardSetController must be instantiated
    // for standard list controllers
    public ApexPages.StandardSetController setCon {
        get {
            if(setCon == null) {
                setCon = new ApexPages.StandardSetController(Database.getQueryLocator(
                    [SELECT ID, Name, unit_price__c FROM GYProduct__c order by unit_price__c desc]));
                    setCon.setPageSize(500);
            }
            return setCon;
        }
        set;
    }
    
  

    // Initialize setCon and return a list of records
    public List<GYP_O_Item__c> retriveProducts() {
    
        List<GYProduct__c> productList = setCon.getRecords();
        
        List<GYP_O_Item__c> inproductItemList = new List<GYP_O_Item__c>();
        Id soldProductRecordId = ApexPages.currentPage().getParameters().get('id');
        
        for(GYProduct__c aProduct : productList){
        
            GYP_O_Item__c needAddItem = new GYP_O_Item__c();
            needAddItem.GYOrder__c = soldProductRecordId;
            needAddItem.GYProduct__c = aProduct.id;
            inproductItemList.add(needAddItem);
        }
        
    
        return inproductItemList;
    }
    
  
    
  
    
     public Pagereference save(){
      
        List<GYP_O_Item__c> insertList = new List<GYP_O_Item__c>();
        for(GYP_O_Item__c item :  this.products ){
            if(item.ProductSoldNumber__c!=null &&item.ProductSoldNumber__c!=0 ){
                insertList.add(item);
            }
        }
        if(insertList.size()>0){
            insert insertList;
        }
       Id soldProductRecordId = ApexPages.currentPage().getParameters().get('id');
       try{
        return new Pagereference('javascript:alert(\'InProductItem(s) Successfully Saved!\');parent.window.opener.location.href=\'/'+soldProductRecordId +'\';window.close();');
       }catch(Exception e){
        return new Pagereference('/'+soldProductRecordId);
       }
      
        
        
        
    }
    
}