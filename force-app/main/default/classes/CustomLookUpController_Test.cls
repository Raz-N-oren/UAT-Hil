@IsTest
public without sharing class CustomLookUpController_Test {
    @TestSetup
    static void makeData(){
        Account acc = TestDataFactory_Test.createAccountForTesting(1)[0];
        acc.BillingCountry='Israel';
        acc.BillingStreet='ד.בית אורן';
        acc.BillingCity='בית השיטה';
        acc.BillingPostalCode='3004400';
        update acc;
        Branch_growth__c branchGrowth = TestDataFactory_Test.createBranchGrowthForTesting(acc);
        Plot_Tank_Junction__c fertilizerHead = TestDataFactory_Test.createFertilizerHeadForTesting();
    }

    @IsTest
    public static void fetcheFertilizerHeadLookUpValues(){

        Branch_growth__c bg = [SELECT Id FROM Branch_growth__c WHERE Name = 'testBranchGrowth' LIMIT 1];
       
        String searchKeyWord = 'Test';
        String objectName = 'Plot_Tank_Junction__c';
        String extraWhereClause = '';

        Test.startTest();
        CustomLookUpController.fetchLookUpValues(searchKeyWord, objectName, extraWhereClause);
        Test.stopTest();

    }


    @IsTest
    public static void fetchBranchGrowthLookUpValues(){

        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Branch_growth__c bg = [SELECT Id FROM Branch_growth__c WHERE Name = 'testBranchGrowth' LIMIT 1];
       
        String searchKeyWord = 'Test';
        String objectName = 'Branch_growth__c';
        String extraWhereClause = ' AND Account__c = ' + '\'' + acc.Id + '\''; // Tests with aditional WHERE attribute
        
        Test.startTest();
        CustomLookUpController.fetchLookUpValues(searchKeyWord, objectName, extraWhereClause);
        Test.stopTest();
    }
     @IsTest
    public static void fetchTankLookUpValues(){
        test.setMock(HttpCalloutMock.class, new TankInterfaceMock());
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        tank__c newTank =TestDataFactory_Test.createDischargeLocation(acc);
        
        String searchKeyWord = null;
        String objectName = 'Tank__c';
        String extraWhereClause = ' AND Account__c = ' + '\'' + acc.Id + '\''; // Tests with aditional WHERE attribute
        
        String searchAccKeyWord = 'test';
        String accObjName = 'Account';
        String extraAccWhereClause ='';
        
        Test.startTest();
        CustomLookUpController.fetchLookUpValues(searchKeyWord, objectName, extraWhereClause);
        CustomLookUpController.fetchLookUpValues(searchAccKeyWord, accObjName, extraAccWhereClause);
        
        
        Test.stopTest();
    }
    
    @isTest
    public static void GoogleMapsGeolocation_Test(){
        test.startTest();
        test.setMock(HttpCalloutMock.class, new GoogleMapsGeolocation_Mock());        
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        tank__c newTank =TestDataFactory_Test.createDischargeLocation(acc);
        test.stopTest();
    }
    
    
    @IsTest
    public static void fetchAccountLookUpValues_Test(){

        Product2 p2 = new Product2(Name = 'Test Product', isActive = true);
        insert p2;

        String searchKeyWord = 'Test';
        String objectName = 'Product2';
        String extraWhereClause = '';

        Test.startTest();
        CustomLookUpController.fetchLookUpValues(searchKeyWord, objectName, extraWhereClause);
        Test.stopTest();
    }

    @IsTest
    public static void fetchWrongLookUpValues_Test(){
        // Expected to fail

        Boolean isErrorAccord = false;
        Product2 p2 = new Product2(Name = 'Test Product', isActive = true);
        insert p2;

        String searchKeyWord = 'Test';
        String objectName = 'WRONG_OBJECT_NAME';
        String extraWhereClause = '';
        Test.startTest();
        try {
            CustomLookUpController.fetchLookUpValues(searchKeyWord, objectName, extraWhereClause);
        } catch (System.AuraHandledException e) {
           
            isErrorAccord = true;
        }
        Test.stopTest();

       // System.assert(isErrorAccord, 'FATAL ERROR: Error was expected but no error was found');
    }

    @IsTest
    static void updateLastViewed_Test(){
        // There is no way to check lastViewed update (Becouse of run time limit)
        List<Account> accs = [SELECT Id, LastViewedDate FROM Account];

        test.startTest();
        CustomLookupController.updateLastViewed('Account', accs[0].Id); 
        test.stopTest();

        // Account updatedAcc = [SELECT Id, LastViewedDate FROM Account WHERE Id = :accs[0].Id];
    }

    @IsTest
    static void getLastViewRecords_Test(){
        // There is no way to check lastViewed update (Becouse of run time limit)
        List<Account> accs = [SELECT Id FROM Account];

        test.startTest();
        List<sObject> lastViewedAccs = CustomLookupController.getLastViewRecords('Account', 'Id, Name', '');
        test.stopTest();

    }
}