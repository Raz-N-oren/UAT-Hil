trigger SampleDataTrigger on Sample_data__c (after insert, after update) {
    new SampleDataTriggerHandler().run(); 
}