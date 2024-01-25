trigger DeliveryNoteTrigger on DeliveryNote__c (before insert,before update,after insert, after update) {
    SWITCH ON trigger.operationType{
        
        WHEN BEFORE_INSERT,BEFORE_UPDATE,AFTER_UPDATE{
         DeliveryNote_CalculateTotalPricing  CalculateTotalPricing= new DeliveryNote_CalculateTotalPricing(trigger.operationType);
        }
       
    }
}