public with sharing class OrderCreditInfoJSON {
    Set<Id> accountIds = new Set<Id>();
    Set<Id> sumOrderAccounts = new Set<Id>();
    Map<Id,Account> relatedAcoounts = new Map<Id,Account>();
    Map<Id,Order> oldMap = (MAP<Id,Order>)trigger.oldMap;
    Map<Id,List<orderItem>> relatedOrderItems= new Map<Id,List<orderItem>>();
    Map<id,AggregateResult>  results = new Map<id,AggregateResult>();
     Map<id,AggregateResult>  relatedDNresults = new Map<id,AggregateResult>();
    
    public map<Id,string> getCreditJSON(){
        map<Id,string> returnMap = new map<Id,string>();
        getAccountIds();
        returnMap= buildJSONAccount();
        return returnMap;
    }
    
    private void getAccountIds(){
        for(Order rec:(List<Order>)trigger.New){
            relatedOrderItems.put(rec.Id,new List<orderItem>());
            accountIds.add(rec.AccountId);
            if(rec.Paying_Customer__c!=null){
                accountIds.add(rec.Paying_Customer__c);
            }
            
        }
        if(!accountIds.isEmpty()){
                results = new Map<id,AggregateResult>([SELECT Order.ActualPayingCustomer__c Id , SUM(TotalLinePrice__c) totalPrice 
                                                       FROM orderItem
                                                       Where Order.ActualPayingCustomer__c IN:accountIds
                                                       AND status__c!='70'
                                                       AND status__c!='100'
                                                       AND status__c!='10'
                                                       AND OrderId NOT IN:(List<Order>)trigger.New
                                                       GROUP BY Order.ActualPayingCustomer__c ]);
            relatedDNresults = new Map<id,AggregateResult>([SELECT Order__r.ActualPayingCustomer__c Id , SUM(TotalPriceBeforeDiscount__c) totalPrice 
                                                            FROM DeliveryNote__c
                                                            Where Order__r.ActualPayingCustomer__c IN:accountIds
                                                            AND BillingDoc__c!=NULL
                                                               AND Order__C NOT IN:(List<Order>)trigger.New
                                                            GROUP BY Order__r.ActualPayingCustomer__c ]);
            relatedAcoounts= new Map<Id,Account>([SELECT Id,Name,Sap_Number__c FROM Account WHERE Id IN:accountIds]);
            
                buildJSONAccount();
            
            
            for(orderItem rec:[SELECT Id,TotalTonWeight__c,orderId,LoadingPoint__c,LoadingPoint__r.LoadingPointSapId__c,LoadingPoint__r.Supplier_Sap_Id__c,
                               order.RequestedSupplyDate__c,product2.ProductCode,product2.sap_number__c,LoadingPoint__r.LoadingPointType__c
                               FROM OrderItem 
                               WHERE status__c!='70' 
                               AND status__c!='100'
                               AND OrderId IN:(List<Order>)trigger.New]){
                relatedOrderItems.get(rec.orderId).add(rec);
            }
        } 
    }
    
    private map<Id,string> buildJSONAccount(){
        map<Id,string> returnMap = new map<Id,string>();
        
        for(Order rec:(List<Order>)trigger.New){
            order old = oldMap!=null && oldMap.get(rec.Id)!=null?oldMap.get(rec.Id):null;
            Decimal sumOpenOrders = results.get(rec.ActualPayingCustomer__c)!=null && results.get(rec.ActualPayingCustomer__c).get('totalPrice')!=null? (decimal)results.get(rec.ActualPayingCustomer__c).get('totalPrice'):0;
            system.debug(loggingLevel.ERROR,'sumOpenOrders:'+sumOpenOrders);
            Decimal sumclosedDNLines = relatedDNresults.get(rec.ActualPayingCustomer__c)!=null && relatedDNresults.get(rec.ActualPayingCustomer__c).get('totalPrice')!=null? (decimal)relatedDNresults.get(rec.ActualPayingCustomer__c).get('totalPrice'):0;
            system.debug(loggingLevel.ERROR,'sumclosedDNLines:'+sumclosedDNLines);
            
            string orderedHazardMaterials='"orderedHazardMaterials": [';
            string isStockAvailable='"isStockAvailable": [';
            string purchaseOrder='"PurchaseOrder": [';
            String payload =' {'+
                '"credit": {'+
                '"userSapNum": "'+(rec.Paying_Customer__c!=null?relatedAcoounts.get(rec.Paying_Customer__c).Sap_Number__c:relatedAcoounts.get(rec.accountId).Sap_Number__c)+'",'+
               '"orderNumber": "'+rec.OrderNumber+'",'+
				'"orderId":"'+rec.Id+'",'+
				'"sumOrder":"'+ (rec.OrderPrice__c!=null?rec.OrderPrice__c:0.00)+'",'+
                '"sumOpenOrders":"'+(sumOpenOrders.setScale(3))+'"'+ //-sumclosedDNLines)+'"'+
               ',"recheck":"'+(rec.recheckCredit__c==true?string.valueOf(rec.recheckCredit__c):'')+'"'+'},';    
            
            system.debug(loggingLevel.ERROR,'rec.recheckCredit__c:'+rec.recheckCredit__c);

            for(orderitem recitem:relatedOrderItems.get(rec.Id)){
                orderedHazardMaterials+=orderedHazardMaterials=='"orderedHazardMaterials": ['? '        {'+
                    '"userSapNum":"'+(rec.Paying_Customer__c!=null?relatedAcoounts.get(rec.Paying_Customer__c).Sap_Number__c:relatedAcoounts.get(rec.accountId).Sap_Number__c)+'",'+
                    '"userSapNum2":"'+(rec.Paying_Customer__c!=null?relatedAcoounts.get(rec.accountId).Sap_Number__c:'')+'",'+
                    '"productSapNum":"'+ recitem.product2.sap_number__c+'",'+
                    '"amountInTonnes":'+recitem.TotalTonWeight__c+'}':',{'+
                    '"userSapNum":"'+(rec.Paying_Customer__c!=null?relatedAcoounts.get(rec.Paying_Customer__c).Sap_Number__c:relatedAcoounts.get(rec.accountId).Sap_Number__c)+'",'+
                    '"userSapNum2":"'+(rec.Paying_Customer__c!=null?relatedAcoounts.get(rec.accountId).Sap_Number__c:'')+'",'+
                    '"productSapNum": "'+recitem.product2.sap_number__c+'",'+
                    '"amountInTonnes":'+recitem.TotalTonWeight__c+'}';
                
                isStockAvailable+=isStockAvailable=='"isStockAvailable": ['?'{'+
                    '"productSapNum":"'+ recitem.product2.sap_number__c+'",'+
                    '"amountInTonnes":'+recitem.TotalTonWeight__c+','+
                    '"DeliveryDate":"'+setDateFormat(rec.RequestedSupplyDate__c)+'"}':',{'+
                    '"productSapNum":"'+recitem.product2.sap_number__c+'",'+
                    '"amountInTonnes":'+recitem.TotalTonWeight__c+','+
                    '"DeliveryDate":"'+setDateFormat(rec.RequestedSupplyDate__c)+'"}';
                
                if(recitem.LoadingPoint__r.LoadingPointType__c=='ספק'){
                    purchaseOrder+=purchaseOrder=='"PurchaseOrder": ['?'{'+
                        '"productSapNum":"'+ recitem.product2.sap_number__c+'",'+
                        '"amountInTonnes":'+recitem.TotalTonWeight__c+','+
                        '"SuplierNumber":"'+recitem.LoadingPoint__r.LoadingPointSapId__c+'"}':',{'+
                            '"productSapNum":"'+recitem.product2.sap_number__c+'",'+
                            '"amountInTonnes":'+recitem.TotalTonWeight__c+','+
                            '"SuplierNumber":"'+recitem.LoadingPoint__r.LoadingPointSapId__c+'"}';
                }
                
            }
            payload+=orderedHazardMaterials+ '],'+'"allHazardMaterialsForUser": {'+'"userSapNum": "'+(rec.Paying_Customer__c!=null?relatedAcoounts.get(rec.Paying_Customer__c).Sap_Number__c:relatedAcoounts.get(rec.accountId).Sap_Number__c)+'"'+'},'+isStockAvailable+']';
            if(purchaseOrder!='"PurchaseOrder": ['){
                payload+=','+purchaseOrder+']}';
            }
            else{
                  payload+='}';
            }
           
            returnMap.put(rec.Id,payload);
        }
        return returnMap;
    }
    
    private string setDateFormat(date dtRequestedDate){
         DateTime dt = NULL;
         String dateStr='';
        IF(dtRequestedDate!=NULL){
         dt = DateTime.newInstance(dtRequestedDate.year(), dtRequestedDate.month(),dtRequestedDate.day());
         dateStr = dt.format('yyyyMMdd');
        system.debug(loggingLevel.ERROR,'formattedDate:'+dateStr);
        }
        return dateStr;
        
    }
    
}