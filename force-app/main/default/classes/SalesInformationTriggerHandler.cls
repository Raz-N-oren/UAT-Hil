public with sharing class SalesInformationTriggerHandler extends TriggerHandler{
    public override void beforeInsert(){
        SalesInformationTriggerHelper.runOverRecords((List<Sales_Information__c>)Trigger.new);        
    }
    
    public override void beforeUpdate(){
        SalesInformationTriggerHelper.runOverRecords((List<Sales_Information__c>)Trigger.new);        
    }
}