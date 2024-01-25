@isTest
private with sharing class AccountStagingBatch_Test {
    final static Integer SUCCESS_ACCOUNT_STAGING_TO_CREATE = 50;
    final static Integer SKIP_ACCOUNT_STAGING_TO_CREATE = 50;

    @TestSetup
    static void makeData(){
        // Create Account records
        List<Account> accs = TestDataFactory_Test.createAccountForTesting(SUCCESS_ACCOUNT_STAGING_TO_CREATE);
        // Create related Account Staging records
        List<Account_Staging__c> accStgRecs =  TestDataFactory_Test.createAccountStagingForCMTesting(accs);
        // Create and add non-related Account Staging records
        accStgRecs.addAll(TestDataFactory_Test.createAccStgRecsWithoutAccounts(SKIP_ACCOUNT_STAGING_TO_CREATE));
        insert accStgRecs;
    }


    @isTest
    static void handleDuplicateId() {
        List<List<Account_Staging__c>> dataLists = createData(false);
        List<Account_Staging__c> accStagingList = dataLists[0];
        List<Account_Staging__c> accStagingList2 = dataLists[1];

        // Insert one contact to the DB to get an Id to duplicate
        Contact con = new Contact(LastName = 'TestLastName', Email = 'con@mail.com');
        insert con;

        // Two other AccountStaging of type - 'Contact Partner' records
        // that will eventually get the same -ID- (Cptel2__c) as an existing contact
        // AccountStaging Cplname__c mandatory and will become LastName field in the contact object after staging
        Account_Staging__c contactAccStage1 = new Account_Staging__c(
            Action_Type__c = 'Contact Partner',
            Status__c = 'Waiting',
            Cptel2__c = con.Id,
            Account_Source__c = accStagingList[0].Account_Source__c,
            Sap_Number__c = accStagingList[0].Sap_Number__c,
            Cplname__c = 'TestCPlname',
            CPmail__c = 'cp@test.com'
        );

        Account_Staging__c contactAccStage2 = new Account_Staging__c(
            Action_Type__c = 'Contact Partner',
            Status__c = 'Waiting',
            Cptel2__c = con.Id,
            Account_Source__c = accStagingList[1].Account_Source__c,
            Sap_Number__c = accStagingList[1].Sap_Number__c,
            Cplname__c = 'TestCPlname',
            CPmail__c = 'cp@test.com'
        );

        accStagingList.add(contactAccStage1);
        accStagingList.add(contactAccStage2);
        insert accStagingList;
        insert accStagingList2;

        Test.startTest();
        AccountStagingBatch asb = new AccountStagingBatch();
        Id batchId = Database.executeBatch(asb);
        Test.stopTest();

        //--------------------------------------------  DB TEST --------------------------------------------
        // Errors
        List<Account_Staging__c> accStageErrorsList = [
            SELECT Action_Type__c, Error_Message__c, Account_Source__c
            FROM Account_Staging__c
            WHERE Status__c = 'Error'
        ];
        for (Account_Staging__c accStage : accStageErrorsList) {
            System.debug(
                'ERROR!: actionType: ' +
                accStage.Action_Type__c +
                '@@  accERROR: ' +
                accStage.Error_Message__c +
                '@@@'
            );
        }

        // Check the ammount of Account_Staging__c records (in DB) of Action_Type__c = 'Contact Partner'
        // with Status__c = 'Success'
        Integer accStagingConStatusSuccess = [
            SELECT COUNT()
            FROM Account_Staging__c
            WHERE Status__c = 'Success' AND Action_Type__c = 'Contact Partner'
        ];
        Integer contactsInDB = [SELECT COUNT() FROM Contact];

        // Test passes only if there were no errors from DB
        // And the amount of successed status Account_Staging__c of Action_Type__c = 'Contact Partner' is exactly 4 (2 from Bulk & 2 with existing Id)
        // If the "duplicate Id" problem wasn't solve we would get an error from DB about it.

        // No errors 
        System.assertEquals(0, accStageErrorsList.size(), 'DB error has occurred: ' + ((accStageErrorsList.size() == 0) ? '' : accStageErrorsList[0]?.Error_Message__c));
        // 1 for each bulk (1) + 2 menualy added = 3 total
        System.assertEquals(3, accStagingConStatusSuccess, 'AccountStaging-Contact Partner records amount is ' + accStagingConStatusSuccess + ', should be 4.');
        // Like the previous line minus 1 duplicate = 2 total
        System.assertEquals(2, contactsInDB, 'Contacts amount in DB is ' + contactsInDB + ', should be 3');
    }
    
    // with parent - not working yet
    private static List<List<Account_Staging__c>> createData(Boolean withParents) {
        //NUM_OF_ACC_STAGING_BULKS_CREATE - Amount of accStaging elements 'Bulks' to create (only create, not inserting)
        final Integer NUM_OF_ACC_STAGING_BULKS_CREATE = 1;
        final String STATUS = 'Waiting';

        // Create one sets of 4 Account_Staging__c, one of each Action_Type__c for 'FER' source
        // Seperate list becouse parant(account) should be inserted first (before child: sa/pf)
        List<Account_Staging__c> accStagingList = TestDataFactory_Test.createAccountStagingRecords(
            NUM_OF_ACC_STAGING_BULKS_CREATE,
            STATUS,
            'FER'
        );

        List<Account_Staging__c> accStagingList2 = new List<Account_Staging__c>();

        // Create one sets of 4 Account_Staging__c, one of each Action_Type__c for each system source
        for(String srcSys : AccountStagingTriggerHelper.sourceSys){
            if(srcSys != 'FER'){
                accStagingList2.addAll(
                    TestDataFactory_Test.createAccountStagingRecords(NUM_OF_ACC_STAGING_BULKS_CREATE, STATUS, srcSys)
                );
            }
        }

        // Move the 'account' Action_Type__c records from accStagingList2 to accStagingList
        for (Integer i = accStagingList2.size() - 1; i >= 0; i--) {
            if (accStagingList2[i].Action_Type__c == 'account') {
                accStagingList.add(accStagingList2.remove(i));
            }
        }

        List<List<Account_Staging__c>> res = new List<List<Account_Staging__c>>();
        res.add(accStagingList);
        res.add(accStagingList2);
        return res;
    }

    // CM Account test (update crdit info for accounts)
    
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
/*
        System.assertEquals(SUCCESS_ACCOUNT_STAGING_TO_CREATE, successRecs, 
            'Number of \'Success\' Account Staging records is wrong');
        System.assertEquals(SKIP_ACCOUNT_STAGING_TO_CREATE, skipedRecs, 
            'Number of \'Skip\' Account Staging records is wrong');*/
    }

    @isTest
    static void accountUpdate_Test() {
        List<Account> accs = [
            SELECT Id, Name, AccountSource, Sap_Number__c, AccountStageId__c, External_Id__c, Amfert_SAP_number__c, 
                IBP_SAP_number__c, QAD1_sap_C__c, US_SAP_NUMBER__c, BRAZIL_SAP_NUMBER__c, Fax, BillingCountryCode
            FROM Account
        ];

        Integer accStgAmountBefore = [SELECT COUNT() FROM Account_Staging__c];
        List<Id> accIds = new List<Id>();
        List<Account_Staging__c> updateAccStgs = new List<Account_Staging__c>();
        for(Integer i = 0 ; i < accs.size() && i < 20 ; i++){
            Account_Staging__c accStg = new Account_Staging__c();
            accStg.Account_Source__c = accs[i].AccountSource;
            accStg.Action_Type__c = 'Account';
            accStg.Account_Name__c = 'New Name ' + i;
            accStg.Fax__c = '1234567' + i;
            accStg.Sap_Number__c = accs[i].Sap_Number__c;
            accStg.Status__c = 'Waiting';
            accStg.Account_Number__c = accs[i].Id;
            accStg.Country__c = 'FR';
            accStg.SAP_AccGr_text__c = 'customer';
            accStg.SAP_Account_Group__c = 'ZCNE';
            accIds.add(accs[i].Id);
            updateAccStgs.add(accStg);
        }
        insert updateAccStgs;
        Integer accStgAmountAfter = [SELECT COUNT() FROM Account_Staging__c];

        Test.startTest();
        AccountStagingBatch asb = new AccountStagingBatch();
        Id batchId = Database.executeBatch(asb);
        Test.stopTest();

        Integer numOfUpdatedAcounts = [SELECT COUNT() FROM Account WHERE Id IN :accIds AND Fax <> null];
      // System.assertEquals(accIds.size(), numOfUpdatedAcounts);
    }
}