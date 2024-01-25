trigger OrderTrigger on Order (before insert,before update,after Insert,after update) {
    
    SWITCH ON trigger.operationType{
        
        WHEN BEFORE_INSERT,BEFORE_UPDATE{
            Order_UpdateStatus UpdateStatus = new Order_UpdateStatus(trigger.operationType);
            Order_Interface SetJSONInterface= new Order_Interface(trigger.operationType);
        }
        WHEN AFTER_INSERT,AFTER_UPDATE{
            Order_UpdateStatus UpdateStatus = new Order_UpdateStatus(trigger.operationType);
            Order_Interface SetJSONInterface= new Order_Interface(trigger.operationType);
            
        }
    }
}