public inherited sharing class PlotsTriggerHandler extends TriggerHandler{
     // publish platform event to refresh multi Picklist LWC which shows apex records
    
     
    
    public override void afterInsert(){
        for (SObject plotSobj : Trigger.New) {
            if (Trigger.New.size()  == 1) { // Platform event expects to handle cases when creating ine plot at a time
                Plot__c p = (Plot__c)plotSobj;
                publishPlotCreatedPlatformEvent(p);
            }
        }
       
    }
    
    static void publishPlotCreatedPlatformEvent(Plot__c p){
        String sError = null;

        Id branchGrowthPlotId = p.Branch_growth__c;
        Id plotAccountId = [SELECT Account__c FROM Branch_growth__c WHERE Id =: branchGrowthPlotId LIMIT 1]?.get(0)?.Account__c;
        if (plotAccountID == null) {
            return; //TODO: Add exception here. Plot account Id must be exists
        }
        List<Plot_Created__e> plotCreatedEventsToPublish = new List<Plot_Created__e>();
        
        Plot_Created__e plotCreatedPlatformEvent = new Plot_Created__e(
        AccountId_of_plot_created__c = plotAccountID);
        plotCreatedEventsToPublish.add(plotCreatedPlatformEvent);
        
        List<Database.SaveResult> results = Eventbus.publish(plotCreatedEventsToPublish);
        for (Database.SaveResult result : results) {
            if (!result.isSuccess()) { //TODO: Handle Error
                for (Database.Error error : result.getErrors()) {
                    System.debug('Error returned: ' +
                    error.getStatusCode() +' - '+
                    error.getMessage());
                    sError = error.getMessage();
                }
                
            }
        }
        
    }
    
}