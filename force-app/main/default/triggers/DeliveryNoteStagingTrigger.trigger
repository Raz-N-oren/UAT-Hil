trigger DeliveryNoteStagingTrigger on Delivery_Note_Staging__c (after insert,after update) {
    SWITCH ON trigger.operationType{
        
        WHEN AFTER_INSERT{
            DeliveryNoteStagingUpsertDN UpsertDN = new DeliveryNoteStagingUpsertDN();
            if(system.isBatch()==false){
                
                DeliveryNoteStaging_SendInvoices SendInvoices  = new DeliveryNoteStaging_SendInvoices();
            }
            
            
        }
     
        WHEN AFTER_UPDATE{
            if(system.isBatch()==false){
              DeliveryNoteStagingUpsertDN UpsertDN = new DeliveryNoteStagingUpsertDN();
                
              DeliveryNoteStaging_SendInvoices SendInvoices  = new DeliveryNoteStaging_SendInvoices();
            }
            
        }
        
        
    }
}