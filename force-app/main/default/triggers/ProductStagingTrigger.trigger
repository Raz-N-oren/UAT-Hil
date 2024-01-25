trigger ProductStagingTrigger on Product_Staging__c (after insert, after update) {

    new ProductStagingTriggerHandler().run(); 
}