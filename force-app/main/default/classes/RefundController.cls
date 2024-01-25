public with sharing class RefundController {
  @AuraEnabled(cacheable=true)
        public static List<DeliveryNote__c> getDeliveryNote(Id Id){
            
          return [SELECT Id, UnitOfMeasure__c, Account__c, Product__c, PayingAccount__c, InvoiceDate__c,Order__r.IntermediaryWarehouse__c, LoadingPoint__c, (SELECT Product__c FROM Delivery_Note_Line_Items__r WHERE LineItemType__c='1') FROM DeliveryNote__c WHERE Id = :Id];
      
    }
}