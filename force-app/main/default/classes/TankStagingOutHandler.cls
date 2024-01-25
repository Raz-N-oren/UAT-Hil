public class TankStagingOutHandler {
    
      public TankStagingOutHandler(){
          
        InterfaceHttpRequest_Batch executeInterface = new InterfaceHttpRequest_Batch('TankStaging__c',trigger.newMap.keySet());
        Database.executeBatch(executeInterface);
    }

}