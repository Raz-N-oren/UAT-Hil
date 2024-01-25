trigger SalesInformationTrigger on Sales_Information__c (before insert, before update) {
    SalesInformationTriggerHandler runHandler =  new SalesInformationTriggerHandler();
    runHandler.run();
}