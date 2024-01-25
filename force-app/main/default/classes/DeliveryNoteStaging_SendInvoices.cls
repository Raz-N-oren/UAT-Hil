public class DeliveryNoteStaging_SendInvoices {
    Map<Id,Delivery_Note_Staging__c> invoiceRecs = new Map<Id,Delivery_Note_Staging__c>();
    
    public DeliveryNoteStaging_SendInvoices(){
        callInterfaceBatch();
    }
    private void callInterfaceBatch(){
        for(Delivery_Note_Staging__c rec:(List<Delivery_Note_Staging__c>)trigger.New){
            if(rec.DeliveryNoteStaging_Type__c=='INVOICE' && userInfo.getUserId()!='00525000008EuuQ'){
                invoiceRecs.put(rec.Id,rec);
            }
        }
        system.debug(loggingLevel.ERROR, 'invoiceRecs.keySet():'+invoiceRecs.keySet());
        IF(!invoiceRecs.isEmpty()){
            InterfaceHttpRequest_Batch executeInterface = new InterfaceHttpRequest_Batch('Delivery_Note_Staging__c',invoiceRecs.keySet());
            Database.executeBatch(executeInterface);
        }
        
    }
}