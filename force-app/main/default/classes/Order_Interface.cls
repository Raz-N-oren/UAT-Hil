public class Order_Interface {
    
    private Map<string,OrderStaging__c> insertOrderStagingRec   = new Map<string,OrderStaging__c>();
    private Map<Id,string> orderJSONMap                         = new Map<Id,string>();
    private Map<Id,string> creditJSONMap                        = new Map<Id,string>();
    public Map<Id,OrderItem> updateOrderItems					= new Map<Id,OrderItem>();
    static Map<string,OrderStaging__c> createNewOS				= new Map<string,OrderStaging__c>();
    private OrderSetJSON getOrderJSONS                          = new OrderSetJSON();
    private OrderCreditInfoJSON getCreditJSON                   = new OrderCreditInfoJSON();
    private Map<Id,AggregateResult> results 					= new Map<id,AggregateResult>();
    static set<id> orderIdsForInterface 						= new set<id>();
    Map<Id,Order> oldOrders										= (Map<Id,order>)trigger.oldMap;
    
    
    
   static GeneralInterfaceData__mdt JSONFields            = new GeneralInterfaceData__mdt();
    
    public Order_Interface(system.TriggerOperation triggerOp){
        if(!system.isBatch() && !system.isFuture())
            system.debug(loggingLevel.Error,'Order_Interface operation:'+triggerOp);
        SWITCH ON triggerOp{
            WHEN BEFORE_UPDATE{
                orderIdsForInterface= new set<id>();
                createNewOS						= new Map<string,OrderStaging__c>();
                system.debug(loggingLevel.Error,'orderIdsForInterface:'+orderIdsForInterface);
                setOrderIdsForInterface();
            }
            
            WHEN AFTER_UPDATE{
                system.debug(loggingLevel.Error,'Order_Interface triggerOp:'+triggerOp);
                setJSONIds(); 
                system.debug(loggingLevel.Error,'orderIdsForInterface:'+orderIdsForInterface);
            }
        }
        
    }
    
    private void setOrderIdsForInterface(){
        for(order rec:(List<Order>)trigger.new){
            system.debug(loggingLevel.Error,'Order_Interface triggerProcessor__c:'+rec.triggerProcessor__c);
            if(rec.triggerProcessor__c==true && 
               ((rec.TransactionType__c=='20' && rec.IsKolDeshen__c==true)||
                ( rec.TransactionType__c!='50' &&  rec.TransactionType__c!='20'  && rec.ConsignationReturnOrder__c==false  && rec.TransactionType__c!='70'))){
                    orderIdsForInterface.add(rec.Id);
                    rec.triggerProcessor__c=false;
                }
            system.debug(loggingLevel.Error,'Order_Interface triggerProcessor__c updated to:'+rec.triggerProcessor__c);

        }
    }
    
    private void setJSONIds(){
        for(order rec:(List<Order>)trigger.new){
            order old =oldOrders!=null && oldOrders.get(rec.Id)!=null?oldOrders.get(rec.Id):null;
            if(orderIdsForInterface.contains(rec.Id)){
                system.debug(loggingLevel.Error,'send interface to Hovalot');

                
                 JSONFields      = JSONFields==null?[SELECT AccountFields__c,ContactFields__c,OrderFields__c,ProductFields__c,OrderItemFields__c
                                                       FROM GeneralInterfaceData__mdt
                                                       WHERE MasterLabel='Order']:JSONFields;
                if(rec.TransactionType__c!='10' && rec.TransactionType__c!='40' && rec.status!='60' && rec.status!='50' ){
                  creditJSONMap=getCreditJSON.getCreditJSON();
                }
                orderJSONMap=orderJSONMap.isEmpty()?getOrderJSONS.getOrderSetJSON((List<Order>)trigger.new):orderJSONMap;
                
                string interfaceType='';            
                string CreditJSON=  creditJSONMap.get(rec.Id)==null ?'':creditJSONMap.get(rec.Id);
                system.debug(loggingLevel.Error,'CreditJSON found:'+CreditJSON);
                string OrderJSON=orderJSONMap.get(rec.Id)!=null?orderJSONMap.get(rec.Id):'';
                system.debug(loggingLevel.Error,'OrderJSON found:'+OrderJSON);
                interfaceType=CreditJSON!=''?'10':'20';
                createNewOrderStagingRec(interfaceType,OrderJSON,CreditJSON,rec.Id,createNewOS);
            }
        }
        if(!createNewOS.isEmpty() )
            insert createNewOS.values();
    }
    
    public static void createNewOrderStagingRec(string InterfaceType,string OrderJSON,string CreditJSON, string relatedOrderId, Map<string,OrderStaging__c> createNewOS){
      
        IF(!system.isFuture() && !system.isBatch()){
            OrderStaging__c rec= new OrderStaging__c(
                Interface_Type__c=InterfaceType,
                Order__c=relatedOrderId,
                CreditJSON__c=CreditJSON,
                OrderJSON__c=OrderJSON
            );
            createNewOS.put(relatedOrderId, rec);
            
            system.debug(loggingLevel.Error,'createNewOrderStagingRec size:'+createNewOS.size());
            
        }

    } 
}