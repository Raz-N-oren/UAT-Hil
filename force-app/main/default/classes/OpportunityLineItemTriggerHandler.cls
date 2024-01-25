public with sharing class OpportunityLineItemTriggerHandler extends TriggerHandler {
    public override void beforeInsert() {
        OpportunityLineItemTriggerHelper.runOverRecords((List<OpportunityLineItem>) Trigger.new);
    }

    public override void beforeUpdate() {
        OpportunityLineItemTriggerHelper.runOverRecords((List<OpportunityLineItem>) Trigger.new);
    }
}