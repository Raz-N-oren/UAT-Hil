public class TankStagingInterfaceResponse {
    set<Id> relatedTankIds = new set<Id>();
        set<string> hovalotIds = new set<string>();
    Map<Id,Tank__c> tanks= new Map<Id,Tank__c>();
        
    public TankStagingInterfaceResponse(){
        setRelatedTanksMap();
        updateRelatedTanks();
    }
    
    
    private void setRelatedTanksMap(){
        for(TankStaging__c rec:(List<TankStaging__c>)trigger.New){
            if(rec.TankResponse__c!=null && rec.TankResponse__c.isNumeric()==true){
                relatedTankIds.add(rec.Tank__c );
            }
        }
        
        if(!relatedTankIds.isEmpty() && tanks.isEmpty()){
            tanks= new Map<Id,Tank__c>([SELECT Id,HovalotId__c FROM Tank__c WHERE Id IN:relatedTankIds]);
        }
    }
    
    private void updateRelatedTanks(){
        for(TankStaging__c rec:(List<TankStaging__c>)trigger.New){
            if(tanks.get(rec.Tank__c)!=null && !hovalotIds.contains(rec.TankResponse__c) &&rec.TankResponse__c!=null && rec.TankResponse__c.isNumeric()==true ){
                tanks.get(rec.Tank__c).HovalotId__c=rec.TankResponse__c;
                hovalotIds.add(rec.TankResponse__c);
                    
            }
            
        }
           list<Database.SaveResult> results = Database.update(tanks.values(), false);
    
    }
}