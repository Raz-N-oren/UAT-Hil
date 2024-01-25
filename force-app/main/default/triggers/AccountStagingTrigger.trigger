trigger AccountStagingTrigger on Account_Staging__c(after update) {
    new AccountStagingTriggerHandler().run();
}