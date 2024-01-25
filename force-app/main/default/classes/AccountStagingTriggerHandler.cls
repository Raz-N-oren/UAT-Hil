public with sharing class AccountStagingTriggerHandler extends TriggerHandler {
   
    // afterUpdate will invoked after Admin changes the Account staging element status from X to 'Waiting'
    // or if Account_Staging__c is updated during one of the triggerHelper method
    public override void afterUpdate() {
        Set<Id> accountStagingId = new Set<Id>();
        for (Account_Staging__c accStage : (List<Account_Staging__c>) Trigger.new) {
            if (accStage.Status__c == 'Waiting') {
                accountStagingId.add(accStage.Id);
            }
        }
        if (!accountStagingId.isEmpty()) {
            AccountStagingTriggerHelper.upsertRecords(accountStagingId);
        }
    }
}