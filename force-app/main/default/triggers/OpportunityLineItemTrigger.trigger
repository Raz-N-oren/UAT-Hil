trigger OpportunityLineItemTrigger on OpportunityLineItem(before insert, before update) {
    OpportunityLineItemTriggerHandler runHandler = new OpportunityLineItemTriggerHandler();
    runHandler.run();
    OpprtunityLineItem_calcProduct calcProduct = new OpprtunityLineItem_calcProduct();
}