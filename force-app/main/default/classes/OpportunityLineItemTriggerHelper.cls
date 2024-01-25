public with sharing class OpportunityLineItemTriggerHelper {
    // Function that calculate the Unit Price of each OLI
    public static void runOverRecords(List<OpportunityLineItem> olis) {
        List<Id> productIds = getProductIds(olis);
        Map<Id, OpportunityLineItem> oppIdToOpp = getOppLineItemInfo(olis);
        addUnitPrice(olis, oppIdToOpp);
    }



    private static Map<Id, OpportunityLineItem> getOppLineItemInfo(List<OpportunityLineItem> olis) {
        Map<Id, OpportunityLineItem> oppIdToOpp = new Map<Id, OpportunityLineItem>([SELECT Id,Opportunity.AccountId,Opportunity.Scope__c,Opportunity.Account.AccountDivision__c ,Loading_Point__c,Transaction_Type__c,Quantity,Unit_of_measure__c,product2.IL_Group__c,Opportunity.RecordTypeId FROM OpportunityLineItem WHERE Id IN :olis]);
        return oppIdToOpp;
    }
    
    private static List<Id> getProductIds(List<OpportunityLineItem> olis) {
        Set<Id> productIds = new Set<Id>();
        for (OpportunityLineItem oppLineItem : olis) {
            productIds.add(oppLineItem.Product2Id);
        }
        return new List<Id>(productIds);
    }

    private static void addUnitPrice(List<OpportunityLineItem> olis,Map<Id, OpportunityLineItem> oppIdToOpp){
        for (OpportunityLineItem oppLineItem : olis){
          OpportunityLineItem rec =  oppIdToOpp.get(oppLineItem.Id)!=NULL?oppIdToOpp.get(oppLineItem.Id):null; 
            if(rec!=null && rec.Opportunity.Scope__c!='כימיקלים'){
               oppLineItem.UnitPrice = priceCalculationInfo.getPrice(rec.product2Id, rec.Opportunity.AccountId, rec.Opportunity.Account.AccountDivision__c , rec.Unit_of_measure__c, rec.Quantity , rec.Loading_Point__c , rec.Transaction_Type__c, rec.product2.IL_Group__c, system.today());
            }
        }
    }
    
}