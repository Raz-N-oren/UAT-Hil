@isTest
public with sharing class PriceOfferController_Test {
    @isTest
    static void getOliIdsByOpp_Test(){
        OpportunityLineItem oli = TestDataFactory_Test.createOpportunityLineItemWithAllDependenciesForTesting();
        insert oli;

        List<Opportunity> opps = [SELECT Id FROM Opportunity];
        Opportunity opp = opps[0];

        List<OpportunityLineItem> oliIds = PriceOfferController.getOliIdsByOpp(opp.Id);
        System.assertEquals(oliIds.size(), 1, 'Should be only one OpportunityLineItem!');
        System.assertEquals(oliIds[0].Id, oli.Id, 'The Ids should be same!');
    }
}