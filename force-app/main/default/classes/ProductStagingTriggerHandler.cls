public with sharing class ProductStagingTriggerHandler extends TriggerHandler {
    
    public override void afterInsert() {
        upsertProductFromStaging();            
    }


    public override void afterUpdate() {
        upsertProductFromStaging();
    }    

    
    private void upsertProductFromStaging(){
        Set<Id> productStagingId = new Set<Id>();
        for (Product_Staging__c proStage : (List<Product_Staging__c>)Trigger.new){
            if(proStage.Status__c == 'New'){
                productStagingId.add(proStage.Id);
            }
        }
        if(!productStagingId.isEmpty()){
            ProductStagingTriggerHelper.upsertRecords(productStagingId);        
        }
    }
}