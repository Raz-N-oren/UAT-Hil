@isTest
public with sharing class AccountStagingBatchSchedule_Test {
    public class AccountsInsertCustomException extends Exception {
    }

    @isTest
    private static void AccountStagingBatchSchedule_Test1() {
        String cronExpr = '0 0 0 15 3 ? 2029'; // Schedule time not actually matter since its running from a test class

        // Test Params
        final Integer NUM_OF_ACC_STAGING_BULKS_CREATE = 1; // Amount of accStaging elements 'Bulks'  to create (only create, not inserting)
        final String STATUS = 'Waiting';
        /*   
         Each 'Bulk' created with the Test Factory Class includes AccountStaging elemetns with a diffrent 'ActionType' and they are releated to each other.
         Elements in a 'Bulk' are releated only to each other and not to other elements that was created in another 'Bulks'.
         The Returned list contains the created accStaging elemets.
         Size of the returned list will be (NUM_OF_ACC_STAGING_BULKS_CREATE * 3)
         */

        List<Account_Staging__c> accStagingList = TestDataFactory_Test.createAccountStagingRecords(
            NUM_OF_ACC_STAGING_BULKS_CREATE,
            'Waiting',
            'FER'
        );

        List<Account> accList = new List<Account>();
        List<Function_Partner__c> accPartenerList = new List<Function_Partner__c>();
        List<Sales_Area__c> accSalesList = new List<Sales_Area__c>();
        List<Contact> contactsList = new List<Contact>();

        // Create Accounts with external ID propery that mutches the incoming accountStaging elements
        // Add the accounts to list
        for (Account_Staging__c accStage : accStagingList) {
            String localObjectExID;
            Integer accNameNumbering = 0;
            if (accStage.Action_Type__c == 'Account') {
                localObjectExID = accStage.Account_Source__c + accStage.Sap_Number__c;
                Account acc = new Account(External_Id__c = localObjectExID, Name = 'accName' + accNameNumbering);
                accList.add(acc);
                accNameNumbering++;
            } else if (accStage.Action_Type__c == 'Sales Area') {
                localObjectExID =
                    accStage.Account_Source__c +
                    accStage.Sap_Number__c +
                    accStage.Business_Unit__c +
                    accStage.Distribution_Channel__c +
                    accStage.Division__c;
                Sales_Area__c accSales = new Sales_Area__c(External_Id__c = localObjectExID);
                accSalesList.add(accSales);
            } else if (accStage.Action_Type__c == 'Partner function') {
                localObjectExID =
                    accStage.Account_Source__c +
                    accStage.Sap_Number__c +
                    accStage.Sap_Number_2__c +
                    accStage.Partnering_TYPE__c;
                Function_Partner__c accPartner = new Function_Partner__c(External_Id__c = localObjectExID);
                accPartenerList.add(accPartner);
            } else if (accStage.Action_Type__c == 'Contact Partner') {
                // TODO: IMPORTANT: why there is no formula for contact in AccStage fields?
                //EXID should be: con.External_id__c = accStage.Account_Source__c + accStage.CpN__c;
                // Why con.Id = accStage.Cptel2__c;? (in triggerHelper)
                localObjectExID = accStage.Account_Source__c + accStage.CpN__c;
                Contact con = new Contact(External_Id__c = localObjectExID, LastName = 'Last Name'); // TODO: Is neccecery?
                contactsList.add(con);
            } else {
                throw new AccountsInsertCustomException(
                    'Could not insert Account/AccountStaging with ActionType: ' + accStage.Action_Type__c
                );
            }
        }

        insert accList;
        insert accPartenerList;
        insert accSalesList;
        insert contactsList;

        // Verify that AsyncApexJob is empty
        // List<AsyncApexJob> jobsBefore = [select Id, ApexClassID, ApexClass.Name, Status, JobType from AsyncApexJob];
        // System.assertEquals(0, jobsBefore.size(), 'not expecting any asyncjobs');

        insert accStagingList; // This will invoke the trigger

        Test.startTest();

        // accStageList[0].Account_Number__c = accList[0].Id; // ID is needed for Action_Type__c = 'Account';
        // update accStageList;

        // Schedule the test job
        String jobId = System.schedule('myJobTestJobName', cronExpr, new AccountStagingBatchSchedule());
        Test.stopTest();

        /*   
        List<Account_Staging__c> accStageDBList = [SELECT Id, Action_Type__c, Account_Number__c, External_Id__c , Status__c FROM Account_Staging__c WHERE Status__c = 'Success'];
        System.assertEquals(3, accStageDBList.size() );
        
        
        // There will now be two things in AsyncApexJob - the Schedulable itself (AccountStagingBatchSchedule)
        // and also the Batch Apex job (AccountStagingBatch)
        
        // Check schedulable is in the job list
        List<AsyncApexJob> jobsScheduled = [select Id, ApexClassID, ApexClass.Name, Status, JobType from AsyncApexJob where JobType = 'ScheduledApex'];
        System.assertEquals(1, jobsScheduled.size(), 'expecting one scheduled job');
        System.assertEquals('AccountStagingBatchSchedule', jobsScheduled[0].ApexClass.Name, 'expecting specific scheduled job');
        
        // check apex batch is in the job list
        List<AsyncApexJob> jobsApexBatch = [select Id, ApexClassID, ApexClass.Name, Status, JobType from AsyncApexJob where JobType = 'BatchApex'];
        System.assertEquals(1, jobsApexBatch.size(), 'expecting one apex batch job');
        System.assertEquals('AccountStagingBatch', jobsApexBatch[0].ApexClass.Name, 'expecting specific batch job');
        
        */
    }
}