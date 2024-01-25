trigger TankTrigger on Tank__c (before insert,before update,After Insert,After update) {
    SWITCH ON trigger.operationType{
        
        WHEN BEFORE_INSERT{
            
            Tank_AutoFieldPopulation AutoFieldPopulation= new Tank_AutoFieldPopulation();
        }
        WHEN BEFORE_UPDATE{
                   if(!system.isFuture())
            Tank_AutoFieldPopulation AutoFieldPopulation= new Tank_AutoFieldPopulation();
        }
        WHEN AFTER_INSERT{
            if(!system.isFuture())
                SetTankJSON newTank = new SetTankJSON(Trigger.operationType);
        }
        WHEN AFTER_UPDATE{
            if(!system.isFuture())
                SetTankJSON newTank = new SetTankJSON(Trigger.operationType);
        }
    }
    
    
}