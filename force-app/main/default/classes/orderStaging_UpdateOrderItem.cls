/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 03-19-2023
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public class orderStaging_UpdateOrderItem {
    set<Id> orderIds                        = new set<Id>();
    set<Id> orderItemsIds                       = new set<Id>();
    List<OrderStaging__c>  triggernew           = new List<OrderStaging__c>();
    List<orderItem> OIForUpdate = new List<orderItem>();
    List<Order> OrderForUpdate = new List<Order>();
    Map<Id,Id> relatedOrderItem             = new Map<Id,Id>();
    Map<Id,OrderItem> relatedOrderItemMaps  = new Map<Id,OrderItem>();
    Map<Id,Order> relatedOrderMaps          = new Map<Id,Order>();
    /* Description: */
    public orderStaging_UpdateOrderItem(List<OrderStaging__c>  triggernew, Map<Id,OrderItem> orderItemsToUpdate){
        this.triggernew=triggernew;
        updateRelatedOrderItemId(orderItemsToUpdate);
    }
    
    public orderStaging_UpdateOrderItem(){
        hovalotOrderItemInterface();
      
    }
  
    private void hovalotOrderItemInterface(){
        List<orderItem> orderItemsToUpdate = new List<orderItem>();
        for(OrderStaging__c rec: (List<OrderStaging__c>)trigger.new){
            if(rec.Interface_Type__c=='30' ){
                system.debug(loggingLevel.ERROR, 'rec.Interface_Type__c:'+rec.Interface_Type__c);
                system.debug(loggingLevel.ERROR, 'rec.OrderItemId__c:'+rec.OrderItemId__c);
                orderItemsIds.add(rec.OrderItemId__c);
            }
        }
        if(!orderItemsIds.isEmpty()){
            relatedOrderItemMaps=new  Map<Id,OrderItem>([ select Id,Quantity,Truck_Code__c,Purchase_Order__c,OrderId,DeliveryDate__c,PointIndex__c,
                                                         order.SAPCreditNotApproved__c,LoadingPoint__r.LoadingPointType__c,LineNumber__c,PointStatus__c,
                                                         UnitOfMeasure__c,DangerousSubstanceNotApproved__c,PurchaseOrderNotApproved__c,Status__c,NumberOfPoint__c
                                                         FROM OrderItem  WHERE Id IN:orderItemsIds]);
        }
        for(OrderStaging__c rec: (List<OrderStaging__c>)trigger.new){    
            if(!relatedOrderItemMaps.isEmpty()){
                if(relatedOrderItemMaps.get(rec.OrderItemId__c)!=null && rec.Interface_Type__c=='30'){
                    relatedOrderItemMaps.get(rec.OrderItemId__c).Truck_Code__c  = rec.Truck_code__c;
                    relatedOrderItemMaps.get(rec.OrderItemId__c).DeliveryDate__c= rec.DeliveryDate__c;
                    relatedOrderItemMaps.get(rec.OrderItemId__c).LineNumber__c  = rec.LineNumber__c;
                    relatedOrderItemMaps.get(rec.OrderItemId__c).Status__c  	= rec.OrderItemStatus__c;
                    relatedOrderItemMaps.get(rec.OrderItemId__c).PointStatus__c	= rec.PointStatus__c;
                    relatedOrderItemMaps.get(rec.OrderItemId__c).PointIndex__c	= rec.PointIndex__c;
                    relatedOrderItemMaps.get(rec.OrderItemId__c).NumberOfPoint__c	= rec.NumberOfPoint__c;
                    
                    orderItemsToUpdate.add(relatedOrderItemMaps.get(rec.OrderItemId__c));
                }
            }
        }
        if(orderItemsToUpdate!=null){
            update orderItemsToUpdate;
            system.debug(loggingLevel.ERROR, 'OIForUpdate size:'+orderItemsToUpdate);
        }
    }
    
    private void updateRelatedOrderItemId(Map<Id,OrderItem> orderItemsToUpdate){
        for(OrderStaging__c rec: triggernew){
            system.debug(loggingLevel.ERROR, 'rec.Interface_Type__c:'+rec.Interface_Type__c);
            system.debug(loggingLevel.ERROR, 'rec.OrderItemId__c:'+rec.OrderItemId__c);
            if(rec.Order__c!=null ){
                orderIds.add(rec.Order__c);
            }
        }
        if(!orderIds.isEmpty()){
            relatedOrderMaps= new Map<Id,Order>([SELECT Id,name,SAPCreditNotApproved__c,recheckCredit__c,CreditStatusReason__c,DangerousSubstanceNotApproved__c,status,Payer_Approval__c ,SapValidationsPerformed__c,(select Id,Quantity,Truck_Code__c,Purchase_Order__c,OrderId,DeliveryDate__c,
                                                                                                 order.SAPCreditNotApproved__c,Status__c,LoadingPoint__r.LoadingPointType__c,LineNumber__c,PointIndex__c,
                                                                                                 UnitOfMeasure__c,DangerousSubstanceNotApproved__c,PurchaseOrderNotApproved__c,NumberOfPoint__c,PointStatus__c
                                                                                                 FROM OrderItems WHERE status__c!='50' AND status__c!='40') from order WHERE ID IN:orderIds]);
            
            system.debug(loggingLevel.ERROR, 'relatedOrderMaps size:'+relatedOrderMaps.size());
        }
        for(OrderStaging__c rec: triggernew){    
            if(relatedOrderMaps!=null && relatedOrderMaps.get(rec.Order__c)!=null && relatedOrderMaps.get(rec.Order__c).status!='60' && relatedOrderMaps.get(rec.Order__c).status!='50'){
                //Sap credit update if the value is different from order
                string  priorStatus 												= relatedOrderMaps.get(rec.Order__c).status;
                boolean OrderUpdateRequire											= false;
                boolean SapValidationsPerformed										= relatedOrderMaps.get(rec.Order__c).SapValidationsPerformed__c;

                relatedOrderMaps.get(rec.Order__c).SAPCreditNotApproved__c 			= rec.SAPCreditNotApproved__c;
                relatedOrderMaps.get(rec.Order__c).CreditStatusReason__C			= rec.CreditStatusReason__c;
                relatedOrderMaps.get(rec.Order__c).SapValidationsPerformed__c		= rec.Interface_Type__c=='20'&& rec.Interface_Type__c!='30' && rec.SAPCreditNotApproved__c==false? true:false;
                relatedOrderMaps.get(rec.Order__c).DangerousSubstanceNotApproved__c = rec.DangerousSubstanceNotApproved__c;
                
                if(rec.SAPCreditNotApproved__c==true){
                    relatedOrderMaps.get(rec.Order__c).status='15';
                }
                else if(rec.DangerousSubstanceNotApproved__c==true ||rec.PurchaseOrderNotApproved__c==true){
                    relatedOrderMaps.get(rec.Order__c).status='20';
                    system.debug(loggingLevel.ERROR, 'updateRelatedOrderItemId -->rec.DangerousSubstanceNotApproved__c:'+rec.DangerousSubstanceNotApproved__c);
                }
                else{relatedOrderMaps.get(rec.Order__c).status					= relatedOrderMaps.get(rec.Order__c).Payer_Approval__c!=null?'30':'10';}
                
                system.debug(loggingLevel.ERROR, 'priorStatus:'+priorStatus+'-->current status:'+relatedOrderMaps.get(rec.Order__c).status);

                /*update related order fields*/
               // if(priorStatus!=relatedOrderMaps.get(rec.Order__c).status ||relatedOrderMaps.get(rec.Order__c).recheckCredit__c==true){
                    relatedOrderMaps.get(rec.Order__c).recheckCredit__c=false;
                    OrderForUpdate.add(relatedOrderMaps.get(rec.Order__c));
              //  }
                system.debug(loggingLevel.ERROR,'SAPCreditNotApproved__c:'+rec.SAPCreditNotApproved__c+'rec.DangerousSubstanceNotApproved__c:'+rec.DangerousSubstanceNotApproved__c+'-->PurchaseOrderNotApproved__c:'+rec.PurchaseOrderNotApproved__c);
            }
            if(orderItemsToUpdate!=null){
                update orderItemsToUpdate.values();
                system.debug(loggingLevel.ERROR, 'OIForUpdate size:'+OIForUpdate);
            }
            if(OrderForUpdate!=null){
                system.debug(loggingLevel.ERROR, 'OrderForUpdate size:'+OrderForUpdate);
                update OrderForUpdate;
            }
        }
    }
}