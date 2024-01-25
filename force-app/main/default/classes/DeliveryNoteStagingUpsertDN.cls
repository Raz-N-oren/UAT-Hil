global class DeliveryNoteStagingUpsertDN {
    set<Id> recIds                					= new set<Id>();// delivery Note Ids

    Map<string, Delivery_Note_Staging__c> DNIds     = new Map<string, Delivery_Note_Staging__c>();// hovalot dn id

	map<Id,Delivery_Note_Staging__c>  DNSMap        = (map<Id,Delivery_Note_Staging__c>)trigger.newMap;
    public DeliveryNoteStagingUpsertDN(){ 
        if(!system.isBatch()){
       		getLookupFieldsInfo();
            if(!recIds.isEmpty()){
                DeliveryNoteStagingUpsertDN_Batch DeliveryNoteStagingUpsertDN= new DeliveryNoteStagingUpsertDN_Batch(recIds);
                database.executeBatch(DeliveryNoteStagingUpsertDN,1);
            }
        }
    }

    private void getLookupFieldsInfo(){
        for(Delivery_Note_Staging__c sortrec:(List<Delivery_Note_Staging__c>)trigger.New){
            if(sortrec.DeliveryNoteStaging_Type__c!='INVOICE'){
                if(DNIds.get(sortrec.DeliveryNoteLineId__c)==null ||(DNIds.get(sortrec.DeliveryNoteLineId__c).createdDate >sortrec.createdDate)){
                    DNIds.put(sortrec.DeliveryNoteLineId__c,sortrec);
                    system.debug('DeliveryNoteStagingUpsertDN-->DNIds:'+DNIds.values());
                    
                }
            }
        }
        if(!DNIds.isEmpty()){
            for(Delivery_Note_Staging__c createDN: DNIds.values()){
                recIds.add(createDN.Id);
                system.debug('DeliveryNoteStagingUpsertDN-->recIds:'+recIds);
            }
        }
    }
}