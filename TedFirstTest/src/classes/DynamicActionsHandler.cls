public with sharing class DynamicActionsHandler {

    public List<CustomObjectDetails> customObjectDetails { get; private set; }
    
    public DynamicActionsHandler(ApexPages.StandardController cont) {
        this.loadCustomObjects();
    }
    
    public void loadCustomObjects() {
        List<CustomObjectDetails> cObjects = new List<CustomObjectDetails>();
        // Schema.getGlobalDescribe() returns lightweight tokens with minimal metadata
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
        for(String obj : gd.keySet()) {
            if(obj.endsWith('__c')) {
                // Get the full metadata details only for custom items
                Schema.DescribeSObjectResult objD = gd.get(obj).getDescribe();
                if( ! objD.isCustomSetting()) {
                    // Save details for custom objects, not custom settings
                    CustomObjectDetails objDetails = new CustomObjectDetails(
                        obj, objD.getLabel(), objD.isCreateable());
                    cObjects.add(objDetails);
                }
            }
        }
        cObjects.sort();
        this.customObjectDetails = cObjects;
    }
    
    public class CustomObjectDetails implements Comparable {
        public String  nameStr   { get; set; }
        public String  labelStr  { get; set; }
        public Boolean creatable { get; set; }
        
        public CustomObjectDetails(String aName, String aLabel, Boolean isCreatable) {
            this.nameStr = aName;
            this.labelStr = aLabel;
            this.creatable = isCreatable;
        }
        
        public Integer compareTo(Object objToCompare) {
            CustomObjectDetails cod = (CustomObjectDetails)objToCompare;
            return(this.nameStr.compareTo(cod.nameStr));
        }
    }
}