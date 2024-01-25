trigger OrderStagingTrigger on OrderStaging__c (before insert,before update,After insert, After Update) {
    
    
    SWITCH ON trigger.operationType{
        WHEN BEFORE_UPDATE{
      
        }
        WHEN AFTER_INSERT,AFTER_UPDATE{
            if(system.isBatch()==false && system.isFuture()==false){
                OrderStaging_HovalotOut HovalotOut = new OrderStaging_HovalotOut();

            }
                orderStaging_UpdateOrderItem UpdateOrderItem= new orderStaging_UpdateOrderItem();
                
            
          
            
          
        }
        
    }
}