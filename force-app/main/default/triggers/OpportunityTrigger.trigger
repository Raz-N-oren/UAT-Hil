trigger OpportunityTrigger on Opportunity (after update) {
    OpportunityTriggerHandler runHandler = new OpportunityTriggerHandler();
    runHandler.run();
}