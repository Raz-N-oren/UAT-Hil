// Send platform event which refreshes the Plots Multi Select PickList in YearlyPlanEdit when a new Plot is created
trigger PlotsTrigger on Plot__c (after insert) {
    new PlotsTriggerHandler().run();
    }