public class SetTankJSON {
    static GeneralInterfaceData__mdt JSONFields 		= [SELECT TankFields__c FROM GeneralInterfaceData__mdt WHERE MasterLabel='Tank'];
    
    public SetTankJSON(System.TriggerOperation operationType){
        SWITCH ON operationType{
            WHEN AFTER_UPDATE,AFTER_INSERT{
                createTankStagingRecords();
            }
        }
    }
    
    public  void createTankStagingRecords(){
        List<TankStaging__c> createTankStaging				= new List<TankStaging__c>();
        Map<Id,Tank__c> additionalInfo = new Map<Id,Tank__c>([SELECT Id,Settlement__r.General_coordinate__c,Settlement__r.General_coordinate__Longitude__s,
                                                              Settlement__r.General_coordinate__Latitude__s,Settlement__r.SETTLEMENT_Address__c ,
                                                              Account__r.BillingStreet,Account__r.BillingCity,Account__r.BillingPostalCode
                                                              FROM Tank__c WHERE Id IN:(List<Tank__c>)trigger.new ]);
       // system.debug(loggingLevel.ERROR, 'RelatedSetelment.get(rec.Settlement__c).SETTLEMENT_Address__c:'+RelatedSetelment.get(rec.Settlement__c).SETTLEMENT_Address__c+'-'+RelatedAccount.get(rec.Account__c).BillingStreet);
        //system.debug(loggingLevel.ERROR, 'RelatedSetelment.get(rec.Settlement__c).Name:'+RelatedAccount.get(rec.Account__c).BillingCity+'-'+RelatedSetelment.get(rec.Settlement__c).Name );

        
        map<Id,string> returnMap = new map<Id,string>();
        string[] tankFields= JSONFields.TankFields__c.split(';');
       
        for(Tank__c rec:(List<Tank__c>)trigger.new){
            string currentEnv= string.valueOf(System.URL.getSalesforceBaseURL());
            string tankJSON='{"Tank":{\n "Env":"'+( currentEnv.contains('uat')?'qa':'prod')+'",';
            Tank__c addedInfo = additionalInfo.get(rec.Id);
         
            if(rec.HovalotId__c==null){
                for(string fId:tankFields){
                    string value =string.valueOf(rec.get(fId));
                    if(value!=null && value.contains('"')){
                        system.debug(loggingLevel.ERROR,'1-->string.valueOf(rec.get(fId):'+value);
                        
                        value=value.replace('"','\\"');
                        system.debug(loggingLevel.ERROR,'2-->string.valueOf(rec.get(fId):'+value);
                        
                    }
                    if(fId=='AccountSapNumber__c' && value!=null){
                        tankJSON+='"'+fId+'":'+'"'+value.replaceFirst( '^0+', '')+'",';
                        
                    }
                    else{
                        tankJSON+='"'+fId+'":'+'"'+value+'",';
                        system.debug(loggingLevel.ERROR, 'fId:'+fId+'-->string.valueOf(rec.get(fId):'+value);
                    }
                   
                    
                }
                system.debug(LoggingLevel.ERROR,'tankJSON:'+tankJSON);
                tankJSON+='}}';
                tankJSON= tankJSON.replaceAll(',}', '}');
                tankJSON= tankJSON.replaceAll('null', '');
                system.debug(loggingLevel.ERROR,'tankJSON Final:'+tankJSON);
                returnMap.put(rec.Id,tankJSON);
              
                
                TankStaging__c OSrec= new TankStaging__c();
                OSrec.Tank__c=rec.Id;
                OSrec.TankJson__c=tankJSON;
                if(addedInfo.Settlement__r.SETTLEMENT_Address__c!=addedInfo.Account__r.BillingStreet ){
                  OSrec.googleInterface__c=true;  
                } 
              
                createTankStaging.add(OSrec);
            }
        }
        
        if(!createTankStaging.isEmpty()){
                            system.debug(loggingLevel.ERROR,'createTankStaging size:'+createTankStaging.size());

            insert createTankStaging;
        }
    } 
    
    
}