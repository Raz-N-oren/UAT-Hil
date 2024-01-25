public class Order_UpdateStatus {
    static set<id> orderIds = null;
    Map<Id,OrderItem> OrderItemsStatusUpdate 						= new Map<Id,OrderItem>();
    static Map<Id,string> orderStatus								= new Map<Id,string>();
    Map<Id,Order> oldOrders											= (Map<Id,order>)trigger.oldMap;
    Map<Id,Order> MapOrders											= (Map<Id,order>)trigger.newMap;
    private Map<Id,AggregateResult> results 					= new Map<id,AggregateResult>();
    boolean updateSumOrders											= false;
    
    
    public  Order_UpdateStatus(system.TriggerOperation triggerOp){
        system.debug(loggingLevel.Error,'Order_UpdateStatus operation:'+triggerOp);
        SWITCH ON triggerOp{
            WHEN BEFORE_INSERT,BEFORE_UPDATE{
                orderIds= new set<id>();
                setOrderStatus();
                getSumOrder();
            }
            
            WHEN AFTER_INSERT,AFTER_UPDATE{
                updateRelatedOrderItems();
                
            }
        }
    }
    
    private void setOrderStatus(){
        for(order rec:(List<Order>)trigger.new){
            order old=oldOrders!=null?oldOrders.get(rec.Id):null;
            system.debug(loggingLevel.ERROR, 'rec.triggerProcessor__c:'+rec.triggerProcessor__c);
            system.debug(loggingLevel.ERROR, 'rec.ActualPayingCustomer__c:'+rec.ActualPayingCustomer__c+'-->rec.OrderPrice__c:'+rec.OrderPrice__c);
            system.debug(loggingLevel.error, 'rec.SAPCreditNotApproved__c:'+rec.SAPCreditNotApproved__c);
            system.debug(loggingLevel.error,'rec.Payer_Approval__c:'+rec.Payer_Approval__c);
            system.debug(loggingLevel.error,'rec.DangerousSubstanceNotApproved__c:'+rec.DangerousSubstanceNotApproved__c );
            system.debug(loggingLevel.error,'rec.PurchaseOrderNotApproved__c:'+rec.PurchaseOrderNotApproved__c );
            system.debug(loggingLevel.error,'rec.InCorrectPricing__c:'+rec.InCorrectPricing__c );

            
            if(rec.status!='60' && (old==null||rec.Status!=old.status||
                 rec.DangerousSubstanceNotApproved__c!=old.DangerousSubstanceNotApproved__c||
                 rec.SAPCreditNotApproved__c!=old.SAPCreditNotApproved__c||
                 rec.PurchaseOrderNotApproved__c!=old.PurchaseOrderNotApproved__c||
                 rec.InCorrectPricing__c!=old.InCorrectPricing__c) &&
               (rec.DangerousSubstanceNotApproved__c==true ||rec.SAPCreditNotApproved__c==true 
                ||rec.PurchaseOrderNotApproved__c>0|| rec.InCorrectPricing__c>0 )){
                   system.debug(loggingLevel.error, 'entered first criteria:'+rec.SAPCreditNotApproved__c);
                   rec.Status=rec.SAPCreditNotApproved__c==true ?'15':'20';
                   rec.SapValidationsPerformed__c=false;
                   orderStatus.put(rec.Id,rec.Status);
                   orderIds.add(rec.Id);
               
                }
            else if(rec.status!='60' && rec.Status!='50' && (rec.TransactionType__c=='20'&& rec.IsKolDeshen__c==false)|| 
                    rec.TransactionType__c=='50'||rec.TransactionType__c=='80'||rec.TransactionType__c=='40'){
                        if(rec.TransactionType__c=='40'){
                            DeliveryNote__c getReturnDN 	= BillingCredit_RelatedDNInfo.getRelatedDNInformation(rec.OriginalDeliveryNote__c);
                            rec.ConsignationReturnOrder__c	= getReturnDN!=null && getReturnDN.order__r.TransactionType__c=='20'?true:false;
                        }
                        system.debug(loggingLevel.error,'entered second criteria');                
                        rec.Status=rec.Payer_Approval__c!=null?'30':'10';
                        orderStatus.put(rec.Id,rec.Status);
                        rec.triggerProcessor__c=rec.TransactionType__c=='40'?true:false;
                        orderIds.add(rec.Id);
            }
            else if(((rec.TransactionType__c!='20' && rec.TransactionType__c!='50')||
                     (rec.TransactionType__c=='20' && rec.IsKolDeshen__c==true)) && 
                    rec.Status!='50' && rec.status!='60'&& rec.SAPCreditNotApproved__c==false &&  
                    rec.InCorrectPricing__c ==0 && rec.DangerousSubstanceNotApproved__c==false && 
                    rec.PurchaseOrderNotApproved__c==0){ 
                               system.debug(loggingLevel.ERROR, '1rec.triggerProcessor__c:'+rec.triggerProcessor__c);
            system.debug(loggingLevel.error,'1rec.Payer_Approval__c:'+rec.Payer_Approval__c);
            system.debug(loggingLevel.error,'1rec.DangerousSubstanceNotApproved__c:'+rec.DangerousSubstanceNotApproved__c );
            system.debug(loggingLevel.error,'1rec.PurchaseOrderNotApproved__c:'+rec.PurchaseOrderNotApproved__c );
            system.debug(loggingLevel.error,'1rec.InCorrectPricing__c:'+rec.InCorrectPricing__c );
                          system.debug(loggingLevel.error,'entered third criteria:'+rec.Id+'  old status:'+(old!=null?old.Status:null)+' new status:'+rec.Status);
                               rec.Status=rec.Payer_Approval__c!=null && rec.Payer_Approval__c!=''?'30':'10';                       
                               orderStatus.put(rec.Id,rec.Status);
                               orderIds.add(rec.Id);
                      if((old!=null && (
                            rec.Status!=old.status||rec.OrderPrice__c !=old.OrderPrice__c ||
                            rec.DangerousSubstanceNotApproved__c!=old.DangerousSubstanceNotApproved__c||
                            rec.SAPCreditNotApproved__c!=old.SAPCreditNotApproved__c||
                            rec.PurchaseOrderNotApproved__c!=old.PurchaseOrderNotApproved__c||
                            rec.InCorrectPricing__c!=old.InCorrectPricing__c)) &&
                           (rec.Status=='10'||rec.Status=='20'||rec.Status=='15'||rec.Status=='30')){
                               rec.triggerProcessor__c=!system.isFuture()||!system.isBatch()? true:false;
                           }
                    }
            else if(rec.Status=='50' && rec.status=='60'){
                orderStatus.put(rec.Id,rec.Status);
                orderIds.add(rec.Id);
            }
            updateSumOrders=!orderIds.isEmpty()||rec.OrderPrice__c==0||rec.OrderPrice__c==null||rec.recheckCredit__c==true?true:updateSumOrders;
            
        }
        
    }
    
    private void updateRelatedOrderItems(){
        List<orderItem> updateOrderItem = new List<orderItem>();
        if(OrderItemsStatusUpdate.isEmpty() && !orderIds.isEmpty()){
            system.debug(loggingLevel.ERROR,'order_updatestatus:orderIds'+orderIds);
            OrderItemsStatusUpdate = new Map<Id,OrderItem>([SELECT Id,Status__c,OrderId,order.TransactionType__c,order.status,order.SapValidationsPerformed__c,order.IsKolDeshen__c,product2.InnerProcess__c FROM OrderItem 
                                                            WHERE OrderId IN:orderIds
                                                            AND Status__c!='100' 
                                                            AND Status__c!='70']);
        }
        
        if(!OrderItemsStatusUpdate.isEmpty()){
            system.debug(loggingLevel.ERROR,'order_updatestatus:OrderItemsStatusUpdate'+OrderItemsStatusUpdate);
            List<orderItem> updateRecs= new List<orderItem>();
            for(orderItem recItem:OrderItemsStatusUpdate.values()){
                order rec = MapOrders.get(recItem.OrderId);
                system.debug(loggingLevel.ERROR,'orderStatus:'+ orderStatus.get(recItem.OrderId));
                system.debug(loggingLevel.ERROR,'order_updatestatus:recItem.Status__c'+recItem.Status__c);
                if(rec.Status=='50' && rec.status=='60'){
                    recItem.status__c='70';
                    updateRecs.add(recItem);
                }
                else if(rec.Payer_Approval__c!=null && rec.Payer_Approval__c!='' && 
                   ((rec.TransactionType__c=='20' && rec.IsKolDeshen__c==false ) ||
                    rec.TransactionType__c=='50'||(rec.TransactionType__c=='80') || 
                    rec.ConsignationReturnOrder__c==true||
                    recItem.product2.InnerProcess__c==TRUE) && recItem.status__c!='100'){
                        OrderItemsStatusUpdate.get(recItem.Id).status__c='100';
                        recItem.status__c='100';
                        system.debug(loggingLevel.ERROR,'orderStatus:1'+ recItem.status__c);
                        updateRecs.add(recItem);
                    }
                else if(rec.TransactionType__c!='20'&& rec.ConsignationReturnOrder__c==false && rec.TransactionType__c!='50' &&  rec.TransactionType__c!='80'){
                    if((rec.status=='20'||rec.status=='15')&& recItem.status__c!='10'){
                        system.debug(loggingLevel.ERROR,'orderStatus:2'+ orderStatus.get(recItem.OrderId));
                        OrderItemsStatusUpdate.get(recItem.Id).status__c='10';
                        recItem.status__c='10';
                        updateRecs.add(recItem);
                    } 
                    else if(rec.status=='30' && recItem.status__c=='10'){
                        system.debug(loggingLevel.ERROR,'orderStatus:3'+ orderStatus.get(recItem.OrderId));
                        OrderItemsStatusUpdate.get(recItem.Id).status__c='20';
                        recItem.status__c='20';
                        updateRecs.add(recItem);
                    }
                }
            }
            
            system.debug(loggingLevel.ERROR,'updateRecs size:'+updateRecs.size());
            if(!updateRecs.isEmpty())
            update updateRecs;
        }
    }
    private void getSumOrder(){
        if(results.isEmpty() && updateSumOrders==true){
            results = new Map<id,AggregateResult>([SELECT OrderId Id , SUM(TotalLinePrice__c)totalPrice ,SUM(CountKolDeshen__c)kolDeshen
                                                   FROM orderItem
                                                   Where OrderId IN:(List<Order>)trigger.new
                                                   GROUP BY OrderId ]);
        }
        system.debug(loggingLevel.ERROR, 'getSumOrder-->results:'+results);
        for(order rec:(List<Order>)trigger.new){
            order old=oldOrders!=null?oldOrders.get(rec.Id):null;
            rec.ActualPayingCustomer__c=rec.Paying_Customer__c!=null ?rec.Paying_Customer__c:rec.AccountId!=null?rec.AccountId:null;
            if(updateSumOrders==true){
                rec.OrderPrice__c = results.get(rec.Id)!=null && results.get(rec.Id).get('totalPrice')!=null?(Decimal)results.get(rec.Id).get('totalPrice'):0;
                rec.IsKolDeshen__c = results.get(rec.Id)!=null && results.get(rec.Id).get('kolDeshen')!=null && (Decimal)results.get(rec.Id).get('kolDeshen')>0?true:false;
                system.debug(loggingLevel.ERROR, 'rec.IsKolDeshen__c:'+rec.IsKolDeshen__c );
                system.debug(loggingLevel.ERROR, 'rec.OrderPrice__c:'+rec.OrderPrice__c );
                updateSumOrders=false;
            }
        }
    }
}