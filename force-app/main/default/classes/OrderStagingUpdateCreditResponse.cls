/* Created By: Lilach Mis
* Description: Check Credit Info from SAP and update related records
*/
public class OrderStagingUpdateCreditResponse{
    
    public  static OrderStaging__c validateAccountApprovedSAP(OrderStaging__c rec,Map<Id,OrderItem> orderItemsToUpdate){
        system.debug(loggingLevel.ERROR, 'CreditJSON__c:'+rec.CreditJSON__c);
        Boolean CreditNotApproved=false;
        Boolean DangerousSubstanceNotApproved=false;
        Map<Id,OrderItem> orderItemsMap = new Map<Id,OrderItem>();
        Map<string,OrderItem> CurrentOrderItemsMap = new Map<string,OrderItem>();
        GeneralInterfaceData__mdt check                = [SELECT ActivateHazardMaterial__c,ActivateCreditCheck__c FROM GeneralInterfaceData__mdt  WHERE MasterLabel='Order'];
        if(rec.CreditResponse__c!=null && rec.CreditResponse__c!=''){
            try{ 
                if(rec.CreditResponse__c!=null ){
                    system.debug(loggingLevel.ERROR, 'rec.CreditResponse__c:'+rec.CreditResponse__c);
                    CreditJSON2Apex obj = CreditJSON2Apex.parse( rec.CreditResponse__c.replace('response status:OK status code:200',''));
                    boolean checkCredit                     = checkAccountCredit(rec.Order__c, rec,obj.Credit, orderItemsMap,CurrentOrderItemsMap);
                    boolean checkHazerdMaterials            = check.ActivateHazardMaterial__c==true ?checkOrderItemHazerdMaterials(rec.Order__c,obj.orderedHazardMaterials, CurrentOrderItemsMap,orderItemsToUpdate ):false;
                    rec.SAPCreditNotApproved__c             = check.ActivateCreditCheck__c==true || test.isRunningTest()==true?checkCredit:false;
                    rec.DangerousSubstanceNotApproved__c    = check.ActivateHazardMaterial__c==true || test.isRunningTest()==true?checkHazerdMaterials:false;
                    rec.PurchaseOrderNotApproved__c         = checkPurchaseOrder(rec.Order__c,rec,obj.PurchaseOrder,orderItemsMap,CurrentOrderItemsMap,orderItemsToUpdate);
                    if(rec.PurchaseOrderNotApproved__c==true||rec.DangerousSubstanceNotApproved__c==true){
                        system.debug(loggingLevel.ERROR, 'rec.DangerousSubstanceNotApproved__c:'+rec.DangerousSubstanceNotApproved__c);
                        
                        string replaceOrderStatus   = rec.OrderJSON__c.contains('"Status":"10"')?'"Status":"10"':rec.OrderJSON__c.contains('"Status":"15"')?'"Status":"15"':'"Status":"30"';
                        string replaceOrderItamStatus ='"Status__c":"20"';
                        system.debug(loggingLevel.ERROR, 'replaceOrderStatus:'+replaceOrderStatus);
                        rec.OrderJSON__c            = rec.OrderJSON__c.replaceAll(replaceOrderStatus,'"Status":"20"');
                        rec.OrderJSON__c            = rec.OrderJSON__c.replaceAll(replaceOrderItamStatus,'"Status__c":"10"');
                    }
                    if(rec.SAPCreditNotApproved__c==true){
                        string replaceOrderStatus   = rec.OrderJSON__c.contains('"Status":"10"')?'"Status":"10"':rec.OrderJSON__c.contains('"Status":"20"')?'"Status":"20"':'"Status":"30"';
                        string replaceOrderItamStatus ='"Status__c":"20"';
                        
                        rec.OrderJSON__c            = rec.OrderJSON__c.replaceAll('"RelStat__c":"R"','"RelStat__c":"B"');
                        rec.OrderJSON__c            = rec.OrderJSON__c.replaceAll(replaceOrderStatus,'"Status":"15"');
                        rec.OrderJSON__c            = rec.OrderJSON__c.replaceAll(replaceOrderItamStatus,'"Status__c":"10"');
                    }
                    
                    if(rec.PurchaseOrderNotApproved__c==false && rec.DangerousSubstanceNotApproved__c==false && rec.SAPCreditNotApproved__c==false){   
                        if(rec.OrderJSON__c!=null && (rec.OrderJSON__c.contains('"Status": "20"')||rec.OrderJSON__c.contains('"Status":"20"')||
                                                      rec.OrderJSON__c.contains('"Status": "15"')||rec.OrderJSON__c.contains('"Status":"15"')||
                                                      rec.OrderJSON__c.contains('"Status": "10"')||rec.OrderJSON__c.contains('"Status":"10"'))){
                                                          
                                                          rec.OrderJSON__c          = rec.OrderJSON__c.replaceAll('"RelStat__c":"B"','"RelStat__c":"R"');
                                                          string replaceOrderStatus     = rec.OrderJSON__c.contains('"Status":"10"')?'"Status":"10"':rec.OrderJSON__c.contains('"Status":"15"')?'"Status":"15"':'"Status":"20"';
                                                          string replaceOrderItamStatus = rec.OrderJSON__c.contains('"Status__c":"10"')?'"Status__c":"10"':'"Status__c":"20"';
                                                          if( rec.orderConfirmation__c!=null && rec.orderConfirmation__c!=''){
                                                              rec.OrderJSON__c          = rec.OrderJSON__c.replaceAll(replaceOrderStatus,'"Status":"30"');
                                                              rec.OrderJSON__c          = rec.OrderJSON__c.replaceAll(replaceOrderItamStatus,'"Status__c":"20"');
                                                              
                                                          }
                                                          else{
                                                              rec.OrderJSON__c          = rec.OrderJSON__c.replaceAll(replaceOrderStatus,'"Status":"10"');
                                                              rec.OrderJSON__c          = rec.OrderJSON__c.replaceAll(replaceOrderItamStatus,'"Status__c":"10"');
                                                          }
                                                          system.debug(loggingLevel.ERROR, 'validateAccountApprovedSAP order status replace to :'+replaceOrderStatus+' --> new order json'+ rec.OrderJSON__c);
                                                      }
                    }
                }
            }
            catch (JSONException e) {
                system.debug(loggingLevel.ERROR, 'validateAccountApprovedSAP Error:'+e.getCause()+'--'+e.getMessage()+' --getLineNumber:'+e.getLineNumber()+'-->'+E.getStackTraceString());
               rec.SAPCreditNotApproved__c=true;
            }
        }
        return rec;
    }
    
    public static void setorderItemMapping(OrderStaging__c rec,Map<Id,OrderItem> orderItemsMap, Map<string,OrderItem> CurrentOrderItemsMap){
        Decimal totalPrice =0;
        List<Order> relatedOrder= new List<Order>([SELECT Id,Paying_Customer__c,AccountId,SAPCreditNotApproved__c,triggerProcessor__c,ResendOrder__c FROM Order WHERE Id=:rec.Order__c]);
        if(relatedOrder.size()>0 ){
            List<OrderItem> Results = [SELECT OrderId,PriceForTon__c,Quantity,product2.dangerous_substance__c,product2.Sap_Number__c,
                                       HazardMaterialPermitNumber__c,HazardMaterialExpirationDate__c,Mat_DG__c,UN_Number__c,Mat_DGDescription__c,
                                       AnnualQuantityHazardMaterial__c,HazardMaterialAllowedQuntity__c,PurchaseOrderNotApproved__c,PurchaseOrderNumber__c,
                                       PurchaseOrderLineItemNumber__c
                                       FROM OrderItem   
                                       WHERE  
                                       ((Order.Paying_Customer__c!=null AND Order.Paying_Customer__c =:relatedOrder[0].Paying_Customer__c)OR(Order.Paying_Customer__c=null AND Order.AccountId=:relatedOrder[0].AccountId) OR (orderId=:rec.Order__c)) AND status__C!='50' AND status__C!='40'];
            for(OrderItem oI:Results){
                if(oI.orderId==rec.Order__c ){
                    CurrentOrderItemsMap.put(oi.product2.Sap_Number__c, oi);
                }
                orderItemsMap.put(oi.Id, oi);
            }
        }
    }
    
    private static boolean checkAccountCredit(string Id,OrderStaging__c rec,CreditJSON2Apex.Credit credit,Map<Id,OrderItem> orderItemsMap,Map<string,OrderItem> CurrentOrderItemsMap){
        boolean CreditNotApproved = false;
        setorderItemMapping(rec,orderItemsMap,CurrentOrderItemsMap);
        system.debug(loggingLevel.error, 'Credit info:CreditStatus-->'+credit.CreditStatus +'- CreditStatusReason-->'+credit.CreditStatusReason);
        if(credit.CreditStatus!=null && credit.CreditStatus=='20'){
            rec.CreditStatus__c=credit.CreditStatus;
            rec.CreditStatusReason__c=credit.CreditStatusReason!=null?credit.CreditStatusReason:null;
            system.debug(loggingLevel.error, 'account  SAP credit not approved because:'+credit.CreditStatusReason); 
            CreditNotApproved=true;
        }
        else{  CreditNotApproved=false; system.debug(loggingLevel.error, 'Account SAP credit approved'); }
        return CreditNotApproved;
    }
    
    private static boolean checkOrderItemHazerdMaterials(string Id,List<CreditJSON2Apex.orderedHazardMaterials> orderedHazardMaterials,Map<string,OrderItem> CurrentOrderItemsMap,Map<Id,OrderItem> orderItemsToUpdate ){
        boolean DangerousSubstanceNotApproved=false;
        if(orderedHazardMaterials!=null && orderedHazardMaterials.size()>0){
            for(CreditJSON2Apex.orderedHazardMaterials OH:orderedHazardMaterials){
                orderItem OI =OH.zmatnrReal!=null&& CurrentOrderItemsMap.get(OH.zmatnrReal.replaceFirst('^0+', ''))!=null?CurrentOrderItemsMap.get(OH.zmatnrReal.replaceFirst('^0+', '')):null;
                Date endDatePermit =OH.endda.replaceFirst('^0+', '')!=''? Date.valueOf(OH.endda.substring(0,4)+'-'+OH.endda.substring(4,6)+'-'+OH.endda.substring(6,8)):null;
                if(OI!=null){
                    if(OI!=null  && OI.product2.Sap_Number__c==OH.zmatnrReal.replaceFirst('^0+','') && OH.matnr.replaceFirst('^0+', '')!='' && ( OH.idperm.replaceFirst('^0+','')=='' || endDatePermit==null|| endDatePermit<system.today()|| OH.maxAmountD.replaceFirst('^0+','')=='')){
                        DangerousSubstanceNotApproved=true;
                        system.debug(loggingLevel.ERROR, 'checkOrderItemHazerdMaterials: '+DangerousSubstanceNotApproved);
                    }
                    system.debug(loggingLevel.error,'OI.HazardMaterialExpirationDate__c:'+OH.endda+'-->Date.valueOf(OH.endda):'+endDatePermit);  
                    OI.HazardMaterialExpirationDate__c  = DangerousSubstanceNotApproved==false ?endDatePermit: null;
                    OI.Mat_DG__c                        = OH.matnr!=null && OH.matnr.replaceFirst('^0+', '')!=''?OH.matnr.replaceFirst('^0+', ''): '';
                    OI.Mat_DGDescription__c             = OH.maktx!=null && OH.maktx.replaceFirst('^0+', '')!=''?OH.maktx: '';
                    OI.UN_Number__c                     = OH.unNumber!=null && OH.unNumber.replaceFirst('^0+', '')!=''?OH.unNumber: '';
                    OI.HazardMaterialPermitNumber__c    = OH.idperm!=null && OH.idperm.replaceFirst('^0+', '')!=''?OH.idperm:'';
                    OI.AnnualQuantityHazardMaterial__c  = OH.yearAmount!=null && OH.yearAmount.replaceFirst('^0+', '')!=''?DEcimal.valueOf(OH.yearAmount.replaceAll('(\\s+)', '')):null;
                    OI.HazardMaterialAllowedQuntity__c  = OH.maxAmountD!=null && OH.maxAmountD.replaceFirst('^0+', '')!=''?DEcimal.valueOf(OH.maxAmountD.replaceAll('(\\s+)', '')):null;
                    orderItemsToUpdate.put(OI.Id,OI);
                }
            }
        }
        return DangerousSubstanceNotApproved;
    }
    
    private static boolean checkPurchaseOrder(string Id,OrderStaging__c rec,
                                              List<CreditJSON2Apex.PurchaseOrder> allPurchaseOrders,
                                              Map<Id,OrderItem> orderItemsMap,
                                              Map<string,OrderItem> CurrentOrderItemsMap,
                                              Map<Id,OrderItem> orderItemsToUpdate){
                                                  
                                                  string purchaseOrderNo = null;
                                                  List<string> getPO= new List<string>();
                                                  if(allPurchaseOrders!=null ){
                                                      for(CreditJSON2Apex.PurchaseOrder PO:allPurchaseOrders){
                                                          if(po.PurchaseOrder[0]!=null){
                                                              getPO.add(po.PurchaseOrder[0]+';'+PO.Line );
                                                              purchaseOrderNo=po.PurchaseOrder[0];
                                                          }
                                                          system.debug(loggingLevel.ERROR,'purchaseOrderNo:'+purchaseOrderNo);
                                                      }
                                                  }
                                                  system.debug(loggingLevel.ERROR,'getPO:'+getPO);
                                                  if(rec.OrderJSON__c!=null && (CurrentOrderItemsMap.size()>0 || allPurchaseOrders!=null)){
                                                      Map<String, Object> m = (Map<String, Object>)JSON.deserializeUntyped(rec.OrderJSON__c);
                                                      Map<String, Object> newMapping =  new Map<String, Object>();
                                                      object relatedOrder = (object)m.get('Order');
                                                      Map<string,Object> orderInfo = ( Map<string,Object>)relatedOrder;
                                                      
                                                      List<Object> a = (List<Object>)m.get('OrderLineItems');   
                                                      List<Object> newa = new List<Object>();
                                                      system.debug(loggingLevel.Error, 'LIST:'+a);
                                                      integer i=0;
                                                      
                                                      for(Object reca:a){
                                                          
                                                          system.debug(loggingLevel.ERROR, ' rec a string:'+reca);
                                                          Map<string,Object> actionType = ( Map<string,Object>)reca;
                                                          system.debug(loggingLevel.ERROR, 'actionType:'+actionType);
                                                          system.debug(loggingLevel.ERROR, 'actionType:'+actionType);
                                                          orderItem relatedOI =CurrentOrderItemsMap.get(string.valueOf(actionType.get('sap_number__c')));
                                                          
                                                          
                                                          if(CurrentOrderItemsMap.get(string.valueOf(actionType.get('sap_number__c')))!=null && string.valueOf(actionType.get('sap_number__c'))!=CurrentOrderItemsMap.get(string.valueOf(actionType.get('sap_number__c'))).Mat_DG__c){
                                                              system.debug(loggingLevel.ERROR, 'Populate orderHazered Material:'+reca);
                                                              actionType.put('HazardMaterialAllowedQuntity__c',relatedOI.HazardMaterialAllowedQuntity__c);
                                                              actionType.put('AnnualQuantityHazardMaterial__c',relatedOI.AnnualQuantityHazardMaterial__c);
                                                              actionType.put('HazardMaterialPermitNumber__c',relatedOI.HazardMaterialPermitNumber__c);
                                                              actionType.put('UN_Number__c',relatedOI.UN_Number__c);
                                                              actionType.put('Mat_DGDescription__c',relatedOI.Mat_DGDescription__c);
                                                              actionType.put('Mat_DG__c',relatedOI.Mat_DG__c);
                                                              actionType.put('HazardMaterialExpirationDate__c',relatedOI.HazardMaterialExpirationDate__c);
                                                              actionType.put('HazardMaterialPermitNumber__c',relatedOI.HazardMaterialPermitNumber__c);
                                                          }
                                                          if(actionType.get('TransactionType__c')=='90' && actionType.get('Status__c')!='50'  && allPurchaseOrders!=null ){
                                                              if( i<getPO.size()){
                                                                  if((object)getPO[i]!=null && string.valueOf((object)getPO[i]).split(';')[0]!='0000000000'){
                                                                      string[] values=string.valueOf((object)getPO[i]).split(';');
                                                                      actionType.put('PurchaseOrderLineItemNumber__c',values[1]);
                                                                      actionType.put('PurchaseOrderNumber__c',values[0]);
                                                                      actionType.put('Purchase_Order__c',values[0]);
                                                                      relatedOI.Purchase_Order__c=values[0];
                                                                      relatedOI.PurchaseOrderNumber__c=values[0];
                                                                      relatedOI.PurchaseOrderLineItemNumber__c=values[1];
                                                                      system.debug(loggingLevel.ERROR,'relatedOI.Purchase_Order__c:'+relatedOI.Purchase_Order__c+'TransactionType__c supplier:'+actionType.get('TransactionType__c')+'  (object)getPO[i]!='+ (object)getPO[i]);
                                                                  }
                                                                  else{
                                                                      relatedOI.Purchase_Order__c=null;
                                                                      relatedOI.PurchaseOrderNumber__c=null;
                                                                      relatedOI.PurchaseOrderLineItemNumber__c=null; 
                                                                  }
                                                                  rec.PurchaseOrderNotApproved__c=(object)getPO[i]==null || string.valueOf((object)getPO[i]).split(';')[0]=='0000000000' ?true:false;
                                                                  relatedOI.PurchaseOrderNotApproved__c= rec.PurchaseOrderNotApproved__c;
                                                                  orderItemsToUpdate.put(relatedOI.Id,relatedOI);
                                                                  i++;
                                                              }
                                                              
                                                          }
                                                          reca=actionType;
                                                          newa.add(reca);
                                                      }
                                                      newMapping.put('OrderLineItems',newa);
                                                      newMapping.put('RelatedContacts',m.get('RelatedContacts'));
                                                      newMapping.put('Order',m.get('Order'));
                                                      rec.OrderJSON__c=JSON.serialize(newMapping);
                                                      
                                                  }
                                                  return rec.PurchaseOrderNotApproved__c;
                                              }
}