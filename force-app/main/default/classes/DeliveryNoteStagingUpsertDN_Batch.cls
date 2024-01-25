global class DeliveryNoteStagingUpsertDN_Batch implements Database.Batchable<sObject>  {
    
    set<Id> relatedRec                              = new set<Id>(); 
    set<string> DeliveryNoteLineIds                 = new set<string>();// delivery Note Ids
    set<string> orderItemIds                        = new set<string>(); 
    set<string> orderIds                        	= new set<string>();
    List<Delivery_Note_Staging__c> updateDNS        = new List<Delivery_Note_Staging__c>();
    Map<Id,Delivery_Note_Staging__c> updateMap		= new  Map<Id,Delivery_Note_Staging__c>();
    
    map<string,Id> relatedDN                        = new map<string,Id>();
    Map<string,orderItem> relatedOI                 = new Map<string,orderItem>();
    Map<string,List<orderItem>> relatedOIByOrder    = new Map<string,List<orderItem>>();
    Map<string,DeliveryNote__c> createDeliveryNote  = new Map<string,DeliveryNote__c>();
    Map<string,string> resultsMap                   = new Map<string,string>();
    GeneralInterfaceData__mdt JSONFields            = [SELECT DeliveryNote__c FROM GeneralInterfaceData__mdt WHERE MasterLabel='DeliveryNote'];
    string[] DNFields								= JSONFields.DeliveryNote__c.split(';');
    
    public DeliveryNoteStagingUpsertDN_Batch(set<Id> recIds){
        relatedRec=recIds;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(InterfaceHttpRequest_Batch.setDynamicQueryObj('Delivery_Note_Staging__c',relatedRec));
    }
    
    global void execute(Database.BatchableContext BC, List<Delivery_Note_Staging__c> records){  
        try{ 
            getLookupFieldsInfo(records);
            queryExternalIds();
            for(Delivery_Note_Staging__c DN: records){
                createDeliveryNotes(DN);
                upsertDeliveryNote();
                updateUpsertResults(DN);      
            }
            updateMap.putAll(updateDNS);//avoid duplications
            update updateMap.values();
        }
        catch(Exception e) {         
            System.debug('Error:TEST' + e.getMessage()+'----'+e.getCause()+'---'+e.getLineNumber()+'---'+e.getTypeName()+'--'+E.getStackTraceString()+'--');  
        }
    }
    
    
    global void finish(Database.BatchableContext BC){ }
    /* Main Functions */
    private void createDeliveryNotes (Delivery_Note_Staging__c rec){
        DeliveryNote__c currentDN= createDeliveryNote.get(rec.DeliveryNoteLineId__c)!= null?createDeliveryNote.get(rec.DeliveryNoteLineId__c):null;
       
        if( rec.BillingDate__c==null && rec.BillingDoc__c==null && (currentDN== null||
         (currentDN!=null && currentDN.LastDeliveryNoteStagingUpdate__c==null || currentDN.LastDeliveryNoteStagingUpdate__r.CreatedDate<rec.CreatedDate))){
            OrderItem OIrec                  			= relatedOI.get(rec.OrderItemId__c)!=null?relatedOI.get(rec.OrderItemId__c):null;
            DeliveryNote__c newDN            			= new DeliveryNote__c();
            newDN.Name                       			= rec.DeliveryNoteLineId__c;
            newDN.DischargeQuantity__c		 			= rec.DischargeQuantity__c;
            newDN.LoadingQuantity__c		 			= rec.LoadingQuantity__c;
            if(OIrec!=null){
                System.debug(loggingLevel.ERROR,'OIrec:'+ OIrec);
                newDN.Account__c            			= OIrec.order.AccountId;
                newDN.LoadingPoint__c       			= OIrec.LoadingPoint__c;
                newDN.LoadingPointName__c				= OIrec.LoadingPointSapId__c;
                newDN.DischargeLocation__c  			= OIrec.DischargeLocation__c;
                newDN.ParentAccount__c					= OIrec.order.Account.ParentId;
                newDN.PaymentTearms__c					= OIrec.RelatedOpportunityItem__c!=NULL?OIrec.RelatedOpportunityItem__r.Terms_of_Payment__c:NULL;
                newDN.OrderItem__c          			= OIrec.Id;
                newDN.LastDeliveryNoteStagingUpdate__c	= rec.Id;
                newDN.RelatedDeliveryNote__c			= OIrec.Order.OriginalDeliveryNote__c;
                newDN.OwnerId							= OIrec.order.Account.Owner.isActive==true?OIrec.order.Account.OwnerId:UserInfo.getUserId();
                newDN.Order__c							= OIrec.OrderId;
                newDN.PayingAccount__c      			= OIrec.Order.Paying_Customer__c;
                System.debug(loggingLevel.ERROR,'newDN.PayingAccount__c:'+ newDN.PayingAccount__c);
                for( string fId:DNFields){
                    newDN.put(fId, rec.get(fId)); 
                } 
                if(createDeliveryNote.get(rec.DeliveryNoteLineId__c)!= null && createDeliveryNote.get(rec.DeliveryNoteLineId__c).InvoiceDate__c==null)
                    newDN.InvoiceDate__c    = NewDN.SupplyDate__c;
                rec.dischargeWeightInTon__c=rec.dischargeWeightInTon__c==null?orderItem_CalculateInfo.calculateTotalTonWeight(rec.DischargeQuantity__c,rec.Dischargequantityuom__c, OIrec.Product2.specific_gravity__c, OIrec.product2.TonWeightCoefficient__c):rec.dischargeWeightInTon__c;      
                System.debug('dischargeWeightInTon__c:'+rec.dischargeWeightInTon__c);
                createDeliveryNote.put(rec.DeliveryNoteLineId__c, newDN);
                System.debug(' createDeliveryNote:'+createDeliveryNote);
            }
        }
        else if( rec.BillingDate__c!=null || rec.BillingDoc__c!=null){
            DeliveryNote__c newDN               = new DeliveryNote__c();
            newDN.BillingDate__c						=REC.BillingDate__c;
            newDN.BillingDoc__c							=REC.BillingDoc__c;
            newDN.DeliveryNoteLineId__c					=rec.DeliveryNoteLineId__c;
            newDN.Status__c								= '60';
            createDeliveryNote.put(newDN.DeliveryNoteLineId__c, newDN);

        }
        else{
            rec.RelatedDeliveryNote__c=createDeliveryNote.get(currentDN.DeliveryNoteLineId__c).Id;
            rec.UpsertResult__c='No need for upsert - DN contains the latest update.';
            updateDNS.add(rec); 
        }
    }
    
    private void upsertDeliveryNote(){
        if(!createDeliveryNote.isEmpty()){
            List<DeliveryNote__c> upsertDNs= new List<DeliveryNote__c>();
            upsertDNs.addAll(createDeliveryNote.values());
            Database.UpsertResult[] results = Database.upsert(upsertDNs, DeliveryNote__c.DeliveryNoteLineId__c);
            for(Integer index = 0, size = results.size(); index < size; index++){
                if(results[index].isSuccess()) {
                    if(results[index].isCreated()){
                        System.debug(upsertDNs[index].DeliveryNoteLineId__c +' Was Created Successfully');
                        resultsMap.put(upsertDNs[index].DeliveryNoteLineId__c ,upsertDNs[index].DeliveryNoteLineId__c+' Was Created Successfully');
                    } else {
                        System.debug(upsertDNs[index].DeliveryNoteLineId__c +' Was Updated Successfully');
                        resultsMap.put(upsertDNs[index].DeliveryNoteLineId__c,upsertDNs[index].DeliveryNoteLineId__c+' Was Updated Successfully');
                    }
                } else{
                    Database.Error err = results.get(index).getErrors().get(0);
                    resultsMap.put(upsertDNs[index].DeliveryNoteLineId__c,upsertDNs[index].DeliveryNoteLineId__c+' Error - '+err.getMessage() + '\nStatus Code : '+err.getStatusCode()+'\n Fields : '+err.getFields());
                    
                    System.debug('Error - '+err.getMessage() + '\nStatus Code : '+err.getStatusCode()+'\n Fields : '+err.getFields());
                }
            }
        }
    }
    
   private void updateUpsertResults(Delivery_Note_Staging__c rec){
        if(relatedDN.isEmpty()){
            List<DeliveryNote__c> upsertDNs= new List<DeliveryNote__c>([SELECT Id,dischargeWeightInTon__c,FKBillingCredit__c,DeliveryNoteLineId__c,
                                                                        TransactionType__c,AllowAssociateOrder__c,Dischargequantityuom__c,
                                                                        TotalTonWeight__c,InventoryManagementOnly__c,Order__c,Account__c,
                                                                        Account__r.AccountDivision__c,LoadingPoint__c,OrderItem__r.TransportType__c,
                                                                        OrderCreatedDate__c,OrderItem__r.product2.IL_Group__c,RelatedDeliveryNote__c,
                                                                        OrderItem__r.product2.specific_gravity__c,PricingDate__c,
                                                                        UnitOfMeasure__c,OrderItem__c,DischargeQuantity__c,LoadingQuantity__c
                                                                        FROM DeliveryNote__c 
                                                                        WHERE DeliveryNoteLineId__c IN:DeliveryNoteLineIds]);
            for(DeliveryNote__c DN:upsertDNs){
                relatedDN.PUT(DN.DeliveryNoteLineId__c,DN.Id);
                DeliveryNoteItem_UpsertLines.createLineItems(DN,relatedOI.get(DN.OrderItem__c));
            }
        }
        if(resultsMap.get(rec.DeliveryNoteLineId__c)!=null){
            rec.RelatedDeliveryNote__c=relatedDN.get(rec.DeliveryNoteLineId__c)!=null?relatedDN.get(rec.DeliveryNoteLineId__c):null;
            rec.UpsertResult__c=resultsMap.get(rec.DeliveryNoteLineId__c);
        }
        updateDNS.add(rec);
    }
    
    /* Get additional data */
    private void getLookupFieldsInfo(List<Delivery_Note_Staging__c> records){
        for(Delivery_Note_Staging__c rec:records){
            if(rec.OrderItemId__c!=null)
                orderItemIds.add(rec.OrderItemId__c);
            if(rec.DeliveryNoteLineId__c!=null)
                DeliveryNoteLineIds.add(rec.DeliveryNoteLineId__c);
        }
    }
    
   private void queryExternalIds(){
          if(relatedDN.isEmpty()){
            List<DeliveryNote__c> upsertDNs= new List<DeliveryNote__c>([SELECT Id,dischargeWeightInTon__c,FKBillingCredit__c,DeliveryNoteLineId__c,
                                                                        TransactionType__c,AllowAssociateOrder__c,Dischargequantityuom__c,
                                                                        TotalTonWeight__c,InventoryManagementOnly__c,Order__c,Account__c,
                                                                        Account__r.AccountDivision__c,LoadingPoint__c,OrderItem__r.TransportType__c,
                                                                        OrderCreatedDate__c,OrderItem__r.product2.IL_Group__c,UnitOfMeasure__c,
                                                                        OrderItem__r.product2.specific_gravity__c,PricingDate__c,OrderItem__c,
                                                                        DischargeQuantity__c,LoadingQuantity__c,LastDeliveryNoteStagingUpdate__c,
                                                                        LastDeliveryNoteStagingUpdate__r.CreatedDate,InvoiceDate__c,RelatedDeliveryNote__c,
                                                                        RelatedDeliveryNote__r.status__C
                                                                        FROM DeliveryNote__c 
                                                                        WHERE DeliveryNoteLineId__c IN:DeliveryNoteLineIds]);
              for(DeliveryNote__c DN:upsertDNs){
                  createDeliveryNote.put(DN.DeliveryNoteLineId__c, DN);
              }
          }
        if(!orderItemIds.isEmpty()){
              List<orderItem> relatedOIs = new List<orderItem>([SELECT Id,Product2Id,Product2.InnerProcess__c,Product2.Sap_Number__c,Product2.IL_Group__c,
                                                                Extension_1__c,Extension_1__r.specific_gravity__c,Extension_1__r.IL_Group__c,
                                                               Extension_Quantity_1__c,Extension_Unit_1__c,Extension_1__r.Product_hierarchy_Code__c,
                                                                Extension_1__r.TonWeightCoefficient__c,Extension_2__r.TonWeightCoefficient__c,
                                                               Extension_2__c,Extension_2__r.specific_gravity__c,Extension_Quantity_2__c,
                                                               Extension_Unit_2__c,Extension_2__r.Product_hierarchy_Code__c,Extension_2__r.IL_Group__c,
                                                               Extension_3__c,Extension_3__r.specific_gravity__c,Extension_Quantity_3__c,Extension_3__r.TonWeightCoefficient__c,
                                                               Extension_1__r.Sap_Number__c,Extension_2__r.Sap_Number__c,Extension_3__r.Sap_Number__c,
                                                               Extension_Unit_3__c,Extension_3__r.Product_hierarchy_Code__c,Extension_3__r.IL_Group__c,
                                                               order.Account.Setelment__c,order.Account.Setelment__r.Geographic_Area__c,UnitOfMeasure__c,
                                                               product2.Product_Hiarch_Type__c,product2.specific_gravity__c,product2.Packing__c,
                                                                product2.TonWeightCoefficient__c,order.Branch_growth__c,order.AgentReceivesCommission__c,
                                                               product2.Product_hierarchy_Code__c,OrderId,TransactionType__c,order.createdDate,TransportType__c,
                                                               TotalTonWeight__c,Quantity,Order.NonFreightCharge__c,order.AccountId,order.Account.OwnerId,order.Account.Owner.isActive,
                                                               order.Account.AccountDivision__c,order.Account.ParentId, Order.TransactionType__c,Order.Paying_Customer__c,
                                                                RelatedOpportunityItem__c,RelatedOpportunityItem__r.Need_a_cart__c,RelatedOpportunityItem__r.Cost_level__c,
                                                                RelatedOpportunityItem__r.Terms_of_Payment__c,LoadingPointSapId__c,LoadingPoint__c,DischargeLocation__c,
                                                                Order.OriginalDeliveryNote__c 
                                                                FROM orderItem
                                                               WHERE Id IN:orderItemIds ]);
            
            for(orderItem oi:relatedOIs){
                relatedOI.put(oi.Id, oi);
            }
        }

    }

}