/**
* @description       : auto populate fields 
* @author            : Lilach mis
* @group             : 
* @last modified on  : 03-30-2022
* @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public class Tank_AutoFieldPopulation{
    Map<Id,Setelment__c> RelatedSetelment	= new Map<Id,Setelment__c>();
    Map<Id,Account> RelatedAccount			= new Map<Id,Account>();
	set<Id> AccountIds 						= new set<Id>();
    set<Id> SetelmentIds 					= new set<Id>();
    
    public  Tank_AutoFieldPopulation(){
        getSetelmentInfo();
        setGeolocationBySettelement();
        
    }
    
    private void getSetelmentInfo(){
        for(Tank__c rec:(List<Tank__c>)trigger.new){
            system.debug(LoggingLevel.ERROR, 'RelatedSetelment:'+RelatedSetelment.values());
           
            if(rec.Location__c==null && rec.Settlement__c!=null){
                SetelmentIds.Add(rec.Settlement__c);
                AccountIds.add(rec.Account__c);
            }
        }
        
        if(RelatedSetelment.isEmpty() && !SetelmentIds.isEmpty()){
            RelatedSetelment=new Map<Id,Setelment__c>([SELECT Id,Name,General_coordinate__c,General_coordinate__Longitude__s,
                                                       General_coordinate__Latitude__s,SETTLEMENT_Address__c  
                                                       FROM Setelment__c 
                                                       WHERE  Id IN:SetelmentIds]);
            system.debug(LoggingLevel.ERROR, 'RelatedSetelment:'+RelatedSetelment.values());
        }
    }
    
    private void setGeolocationBySettelement(){
        for(Tank__c rec:(List<Tank__c>)trigger.new){
            if(rec.Location__c==null && RelatedSetelment.get(rec.Settlement__c)!=null ){
                system.debug(LoggingLevel.ERROR, 'RelatedSetelment.get(rec.Settlement__c):'+RelatedSetelment.get(rec.Settlement__c));

                    rec.Location__Latitude__s=RelatedSetelment.get(rec.Settlement__c).General_coordinate__Latitude__s;
                    system.debug(LoggingLevel.ERROR, 'rec.Location__Latitude__s:'+rec.Location__Latitude__s);
                    
                    rec.Location__Longitude__s= RelatedSetelment.get(rec.Settlement__c).General_coordinate__Longitude__s;
                    system.debug(LoggingLevel.ERROR, ' rec.Location__Longitude__s:'+ rec.Location__Longitude__s);
            }
        }
    }
}