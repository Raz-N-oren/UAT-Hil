global class DoubleOPTInScheduledBatch implements Database.Batchable<sObject> , schedulable {
    global void execute(SchedulableContext SC) {
        database.executebatch(new DoubleOPTInScheduledBatch());
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        string status='Waiting';
        string query = 'SELECT Id,Email__c,LandscaperProNewsletter__c ,RelatedDigitalExId__c FROM Double_OPT_In__c WHERE  RelatedDigitalExId__c!=null AND Status__c=:status';
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext bc, List<Double_OPT_In__c> DOIList){
        
        Set<Id> relatedDigitalExRecs= new set<Id>();
        Map<string,Double_OPT_In__c> DOIMap= new Map<string,Double_OPT_In__c>();
        List<Double_OPT_In__c> updateDOI= new List<Double_OPT_In__c>();
        Map<Id,Digital_Input__c> relatedDI= new Map<Id,Digital_Input__c>();
        for(Double_OPT_In__c DOI:DOIList){
            try{
                if(DOI.RelatedDigitalExId__c!=null && (DOI.RelatedDigitalExId__c.startsWith('a1F')==true||DOI.RelatedDigitalExId__c.startsWith('a1L')==true)){
                    system.debug(logginglevel.ERROR,'DOI.RelatedDigitalExId__c:'+DOI.RelatedDigitalExId__c);
                    relatedDigitalExRecs.add(DOI.RelatedDigitalExId__c);
                    DOIMap.put(DOI.RelatedDigitalExId__c,DOI);
                }
                if(!relatedDigitalExRecs.isEmpty()){
                    system.debug(logginglevel.ERROR,'relatedDigitalExRecs:'+relatedDigitalExRecs+'  DOIMap:'+DOIMap);
                    relatedDI= new Map<Id,Digital_Input__c>([
                        SELECT Id,Email__c,DoubleOPTInVerified__c 
                        FROM Digital_Input__c
                        WHERE Id IN:relatedDigitalExRecs]);
                    if(!relatedDI.isEmpty()){
                        for(Double_OPT_In__c rec:DOIMap.values()){
                            
                            if(relatedDI.get(rec.RelatedDigitalExId__c)!=null){
                                relatedDI.get(rec.RelatedDigitalExId__c).Email__c=rec.Email__c;
                                relatedDI.get(rec.RelatedDigitalExId__c).DoubleOPTInVerified__c=rec.LandscaperProNewsletter__c;
                           
                            }
                        }
                    }
                }
            }
            catch(Exception e){
                system.debug(loggingLevel.ERROR,'Double Opt-IN Error:Cause-->'+e.getCause()+' Message-->'+e.getMessage()+' line:'+e.getLineNumber());
                continue;
            }
            if(!relatedDI.isEmpty()){
                List<Digital_Input__c> updateDI= new List<Digital_Input__c>();
                updateDI.addAll(relatedDI.values());
                Database.SaveResult[] results = Database.update(updateDI,false);
                for(Integer index = 0, size = results.size(); index < size; index++){
                    if(results[index].isSuccess()){
                        System.debug(updateDI[index] +' Was updated Successfully');
                        DOIMap.get(string.valueOf((updateDI[index].Id)).substring(0,15)).status__c='Success';
                    } else{
                        Database.Error err = results.get(index).getErrors().get(0);
                        System.debug(loggingLevel.error,'updateDI[index]:'+updateDI[index]+'  string.valueOf((updateDI[index].Id)).substring(0,15):'+string.valueOf((updateDI[index].Id)).substring(0,15));
                        DOIMap.get(string.valueOf((updateDI[index].Id)).substring(0,15)).ErrorMsg__c= ' Error - '+err.getMessage() + '\nStatus Code : '+err.getStatusCode()+'\n Fields : '+err.getFields();
                    }
                }
            }
            if(!DOIMap.isEmpty())
                update DOIMap.values();
        }
    }


    
    
    
    global void finish(Database.BatchableContext bc){
        String strJobName = 'Job-DoubleOPTInScheduledBatch Next Run:'+system.now().addMinutes(10);
        if(!Test.isRunningTest()){String jobID =system.scheduleBatch(new DoubleOPTInScheduledBatch(), strJobName, 10);}
    }
}