@isTest
private class SuperClone_Test {

    @TestSetup
    static void makeData(){ // Inserts Data to DB for test metods. Availble for all Tests in this class
        
        final Integer NUM_OF_ACCOUNTS_TO_CREATE = 1;
        
        Account acc = TestDataFactory_Test.createAccountForTesting(NUM_OF_ACCOUNTS_TO_CREATE)[0];
        Branch_growth__c branchGrowth = TestDataFactory_Test.createBranchGrowthForTesting(acc);
        Plot__c plot = TestDataFactory_Test.createPlotForTesting(acc, branchGrowth);
        Growth__c growth = TestDataFactory_Test.createGrowthForTesting(plot);
        
        Product2 p2 = new Product2(Name = 'Test Product', isActive = true);
        insert p2;

        PricebookEntry pbe = TestDataFactory_Test.createPriceBookEntryForTesting(p2);
        Opportunity opp = TestDataFactory_Test.createOpportunityForTesting(acc);
        OpportunityLineItem oli = TestDataFactory_Test.createOpportunityLineItemForTesting(acc, opp, p2, pbe);
        insert oli;
    }

    @isTest
    private static void doClone_Test() {

        Danger_Gods_Permit__c dg = new Danger_Gods_Permit__c();

        insert dg;

        Permit_Products__c pp = new Permit_Products__c();

        pp.Danger_Gods_Permit__c = dg.Id;

        insert pp;

        Test.startTest();
        Id clonedId =  SuperClone.doClone(dg.Id);
        Test.stopTest();
    }

    @isTest
    private static void doCloneOppWithPlots_Test(){
        Account acc = [SELECT Id FROM Account WHERE Name='Test Account' LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name='Test Oppertunity' LIMIT 1];
        Plot__c plot = [SELECT Id FROM Plot__c WHERE Name='Test Plot' LIMIT 1];

        Product2 p2 = new Product2(Name = 'Test Product', isActive = true);
        insert p2;

        Test.startTest();
        SuperClone.doCloneOppWithPlots(opp.Id, acc.Id, 'PlotNames', 'growthName', 99);
        Test.stopTest();
    }
}