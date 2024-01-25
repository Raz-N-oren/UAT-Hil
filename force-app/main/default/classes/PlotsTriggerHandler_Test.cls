@isTest
public with sharing class PlotsTriggerHandler_Test {

    @isTest
    public static void createNewPlotPlatformEventTest() {


        final Integer NUM_OF_ACCOUNTS_TO_CREATE = 1;
        
        Account acc = TestDataFactory_Test.createAccountForTesting(NUM_OF_ACCOUNTS_TO_CREATE)[0];
        Branch_growth__c branchGrowth = TestDataFactory_Test.createBranchGrowthForTesting(acc);
        Plot__c plot = TestDataFactory_Test.createPlotForTesting(acc, branchGrowth);
        Growth__c growth = TestDataFactory_Test.createGrowthForTesting(plot);

        Test.startTest();
        Test.stopTest();


    }
}