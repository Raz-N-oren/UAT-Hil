trigger TankStagingTrigger on TankStaging__c (After insert, After Update) {
    
  if(system.isBatch()==false && system.isFuture()==false ){
       TankStagingOutHandler StagingOutHandler = new TankStagingOutHandler();
    }
    
    TankStagingInterfaceResponse InterfaceResponse= new TankStagingInterfaceResponse();
    
}