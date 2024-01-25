@isTest
private with sharing class AccountStagingCMSBatch_Test {
    final static Integer SUCCESS_ACCOUNT_STAGING_TO_CREATE = 60;
    final static Integer SKIP_ACCOUNT_STAGING_TO_CREATE = 60 ;

    @TestSetup
    static void makeData(){
        // Create Account records
        List<Account> accs = TestDataFactory_Test.createAccountForTesting(SUCCESS_ACCOUNT_STAGING_TO_CREATE);
        // Create Account CMS records
        List<Account> accCMS = TestDataFactory_Test.createAccountCMSForTesting(SUCCESS_ACCOUNT_STAGING_TO_CREATE);
        // Create related Account Staging records
        List<Account_Staging__c> accStgRecs =  TestDataFactory_Test.createAccountStagingForCMTesting(accs);
         // Create related Account Staging records
        List<Account_Staging__c> accStgCMSRecs =  TestDataFactory_Test.createAccountStagingForCMSTesting(accCMS);
        // Create and add non-related Account Staging records
        accStgRecs.addAll(TestDataFactory_Test.createAccStgRecsWithoutAccounts(SKIP_ACCOUNT_STAGING_TO_CREATE));
        insert accStgRecs;
    }
    
    @isTest
    static void CMAcountTest() {
        Test.startTest();
        // Run the batch
        AccountStagingBatch asb = new AccountStagingBatch();
        Id batchId = Database.executeBatch(asb);
        Test.stopTest();

        // Check that the existing Account records updated and the 'not existing' ones are removed from the 
        // Account Staging (in DB)
               
        List<Account> dbAccs = [
            SELECT Id, Name, AccountSource, Sap_Number__c,External_Id__c, Classification__c, 
                Customer_credit_file_in_CM__c, SABNR__c, KLIMK__c, OBLIG__c, RISKCL__c, 
                OPUFAE__c, ATLBRTG__c, VIPCUS__c, JOINTCUS__c, AccountStageId__c
            FROM Account
        ];

        List<Account_Staging__c> dbAccStgs = [SELECT Id, Name, Sap_Number__c, Status__c FROM Account_Staging__c];
        Integer skipedRecs = [SELECT count() FROM Account_Staging__c WHERE Status__c = 'Skip'];
        Integer successRecs = [SELECT count() FROM Account_Staging__c WHERE Status__c = 'Success'];

       // System.assertEquals(SUCCESS_ACCOUNT_STAGING_TO_CREATE, successRecs-2, 
         //   'Number of \'Success\' Account Staging records is wrong');
   
    }

}