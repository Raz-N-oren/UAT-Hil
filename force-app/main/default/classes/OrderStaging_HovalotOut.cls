public class OrderStaging_HovalotOut {
    set<Id> sendToHovalot = new set<Id>();
   
    
    public OrderStaging_HovalotOut(){
        if(!system.isBatch() && !system.isFuture()) 
            SendToHovalot(); 
    }
    
    private void SendToHovalot(){
        for(OrderStaging__c rec: (List<OrderStaging__c>)trigger.new){
            if(rec.Interface_Type__c=='20'||rec.Interface_Type__c=='10')
                sendToHovalot.add(rec.Id);
        }
        
        if(!sendToHovalot.isEmpty()){
			system.debug(loggingLevel.ERROR, 'test');
            InterfaceHttpRequest_Batch executeInterface = new InterfaceHttpRequest_Batch('OrderStaging__c',sendToHovalot);
            Database.executeBatch(executeInterface,1);
        }
    }
}