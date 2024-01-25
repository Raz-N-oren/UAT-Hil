@isTest
public with sharing class YearlyPlanController_Test {
    
    // TODO: Assertions

    @TestSetup
    static void makeData(){ // Inserts Data to DB for test metods. Availble for all Tests in this class
        
        final Integer NUM_OF_ACCOUNTS_TO_CREATE = 1;
        
        Account acc = TestDataFactory_Test.createAccountForTesting(NUM_OF_ACCOUNTS_TO_CREATE)[0];
        Branch_growth__c branchGrowth = TestDataFactory_Test.createBranchGrowthForTesting(acc);
        Plot__c plot = TestDataFactory_Test.createPlotForTesting(acc, branchGrowth);
        Growth__c growth = TestDataFactory_Test.createGrowthForTesting(plot);
        
        Opportunity opp = TestDataFactory_Test.createOpportunityForTesting(acc);
        Product2 p2 = new Product2(Name = 'Test Product', isActive = true);
        insert p2;
        
        //TODO: Move to testDataFactory Class
        PricebookEntry pbe = new PricebookEntry(
        Pricebook2Id = Test.getStandardPricebookId(),
        Product2Id = p2.Id,
        UnitPrice = 99,
        isActive = true
        );
        insert pbe;
        
        //TODO: Move to testDataFactory Class
        OpportunityLineItem oli = new OpportunityLineItem(
        PriceBookEntryId = pbe.Id,
        OpportunityId = opp.Id,
        Quantity = 1,
        TotalPrice = 99
        );
        
        YearlyPlanController.getFertilizationSuggestions('גזר');
        list<OpportunityLineItem> oppLi =  YearlyPlanController.getOppProducts(opp.Id);

    }
    
    @isTest
    private static void getPlots_Test() {
        
        Account acc = [SELECT Id FROM Account WHERE Name='Test Account' LIMIT 1];
        Test.startTest();
        YearlyPlanController.getPlots(acc.Id);
        Test.stopTest();
    }
    
    
    @isTest
    private static void getOppLineItemDataMdt(){
        
        Test.startTest();
        YearlyPlanController.getOppLineItemDataMdt('Extension');
        Test.stopTest();
        
    }
    
    @isTest
    private static void getPlotGrowthType(){
        
        Plot__c plot = [SELECT Id FROM Plot__c WHERE Name='Test Plot' LIMIT 1];
        
        Test.startTest();
        YearlyPlanController.getPlotGrowthType(plot.Id);
        Test.stopTest();
    }
    
    @isTest
    private static void getFertilizationSuggestions(){
        
        Test.startTest();
        YearlyPlanController.getFertilizationSuggestions('גזר');
        Test.stopTest();
        
    }
    
    @isTest
    private static void getOppProducts(){

        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name='Test Oppertunity' LIMIT 1];
        Test.startTest();
        YearlyPlanController.getOppProducts(opp.Id);
        Test.stopTest();
    }


    @isTest
    private static void captureAccId(){

    /**********************************************************************************************************************
    *  # captureAccId(oppId) checks if opp.accId != lastAccount who 'visits' the page who holds the component             *
    *  # This tests checks assures that the LVA-lastViewAccount is cupdated to the last opp.AccId who visit the component *
    ***********************************************************************************************************************/

    //TODO: move user creation to test dataFactory + Check as user diffrent then Admin
    Profile prof = [Select Name From Profile WHERE (UserType = 'Standard' AND PermissionsPrivacyDataAccess = true) Order By CreatedDate ASC LIMIT 1];
    User usr = new User(LastName = 'test',
    FirstName='test',
    Alias = 'test',
    Email = 'test.Bhardwaj@asdf.com',
    Username = 'test.Bhardwaj@asdf.com',
    ProfileId = prof.id,
    TimeZoneSidKey = 'GMT',
    LanguageLocaleKey = 'en_US',
    EmailEncodingKey = 'UTF-8',
    LocaleSidKey = 'en_US'
    );


    List<Account> accList = TestDataFactory_Test.createAccountForTesting(2);
    Opportunity opp1 = TestDataFactory_Test.createOpportunityForTesting(accList[0]);
    Opportunity opp2 = TestDataFactory_Test.createOpportunityForTesting(accList[1]);

    Last_Viewed_Account__c lva = new Last_Viewed_Account__c(
    SetupOwnerId = usr.Id,    
    Account_Id__c = accList[0].Id);
    insert lva;

    System.runAs(usr)
    {
        Test.startTest();
         // Second test with Accound ID which should much the lva accountID
        Boolean isLastViewedAccountIdIsUpdatedTest1 =  YearlyPlanController.captureAccId(opp1.Id);
        // Second test with Accound ID which should NOT much the lva accountID
        lva.Account_Id__c = opp2.AccountId;
        update lva;
        Boolean isLastViewedAccountIdIsUpdatedTest2 = YearlyPlanController.captureAccId(opp1.Id);
        Test.stopTest();

        System.assertEquals(false , isLastViewedAccountIdIsUpdatedTest1);
        System.assertEquals(true, isLastViewedAccountIdIsUpdatedTest2);


    }

        
}


    
}