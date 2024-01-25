public with sharing class OpportunityTriggerHandler extends TriggerHandler {
    public override void afterUpdate() {
        OpportunityTriggerHelper.manageOpportunities();
    }
}