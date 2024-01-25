trigger DeliveryNoteItemsTrigger on DeliveryNoteItems__c (before insert, before update, after update, after insert ) {
    
  DeliveryNoteItem_PopulateLineItemInfo PopulateLineItemInfo = new DeliveryNoteItem_PopulateLineItemInfo(trigger.operationType);

}