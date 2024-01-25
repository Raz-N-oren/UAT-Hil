@isTest
private with sharing class AccountStagingTriggerHelper_Test {
     
     public class AccountsInsertCustomException extends Exception {}
     
     @TestSetup
     static void makeData(){
          //NUM_OF_ACC_STAGING_BULKS_CREATE - Amount of accStaging elements 'Bulks' to create
          // (creating without inserting)
          final Integer NUM_OF_ACC_STAGING_BULKS_CREATE = 1; 
          final String STATUS = 'Waiting';
          /*   
               Each 'Bulk' created with the Test Factory Class includes AccountStaging elemetns with a diffrent 
               'ActionType' and they are releated to each other.
               Elements in a 'Bulk' are releated only to each other and not to other elements that was created in another 'Bulks'.
               The Returned list contains the created accStaging elemets.
               Size of the returned list will be (NUM_OF_ACC_STAGING_BULKS_CREATE * 3)
          */
          
          List<Account_Staging__c> accStagingList = new List<Account_Staging__c>();
          for(String SysSrc : AccountStagingTriggerHelper.sourceSys){
               accStagingList.addAll(TestDataFactory_Test.createAccountStagingRecords(
                    NUM_OF_ACC_STAGING_BULKS_CREATE, STATUS, SysSrc
               )); 
          }

          List<Account> accList = new List<Account>();
          List<Function_Partner__c> accPartenerList = new List<Function_Partner__c>();
          List<Sales_Area__c> accSalesList = new List<Sales_Area__c>();
          List<Contact> contactsList = new List<Contact>();
          
          
          // Create Accounts with external ID property that mutches the incoming accountStaging elements
          // Add the accounts to list
          for (Account_Staging__c accStage : accStagingList) {
               String localObjectExID;
               Integer accNameNumbering = 0;
               if (accStage.Action_Type__c == 'Account') {
                    localObjectExID = accStage.Sap_Number__c;
                    Account acc = new Account( External_Id__c = localObjectExID, Name = 'accName' + accNameNumbering);
                    accList.add(acc);
                    accNameNumbering++;
               }
               else if (accStage.Action_Type__c == 'Sales Area') {
                    localObjectExID = accStage.Account_Source__c + accStage.Sap_Number__c + accStage.Business_Unit__c 
                         + accStage.Distribution_Channel__c + accStage.Division__c;
                    Sales_Area__c accSales = new Sales_Area__c(External_Id__c = localObjectExID);
                    accSalesList.add(accSales);
               }
               else if(accStage.Action_Type__c == 'Partner function'){
                    localObjectExID = accStage.Account_Source__c + accStage.Sap_Number__c + accStage.Sap_Number_2__c 
                         + accStage.Partnering_TYPE__c;
                    Function_Partner__c accPartner = new Function_Partner__c(External_Id__c = localObjectExID);
                    accPartenerList.add(accPartner);
               }
               else if(accStage.Action_Type__c == 'Contact Partner'){
                    //EX_ID should be: con.External_id__c = accStage.Account_Source__c + accStage.CpN__c;
                    localObjectExID = accStage.Account_Source__c + accStage.CpN__c;
                    Contact con = new Contact(External_Id__c = localObjectExID, LastName = 'Last Name');
                    contactsList.add(con);
               }
               
               else {
                    throw new AccountsInsertCustomException('Could not insert Account/AccountStaging with ActionType: ' + accStage.Action_Type__c);
               }
          }
          insert accList;
          insert accPartenerList;
          insert accSalesList;
          insert contactsList;
          insert accStagingList; // This will not the trigger (only after update)
     }
     

     @isTest
     static void accountStagingTriggerHelperInsertTest() {
          /*
          NOTES:
          #  The trigger handler afterUpdate() is invoked only by the AccountStagingBatchSchdule_Test
          # Batch -> Nothing (Empty test)
          # BatchSchdule_Test -> BatchSchdule -> Trigger#HELPER# ->TriggerHandler afterUpdate() without enter the IFs ##afterInsert() is commented## 
          # TriggerHelper_Test -> TriggerHandler afterUpdate() without enter the IFs ##afterInsert() is commented##
          */
          
          
          Test.startTest();
          Test.stopTest(); 
          
          //--------------------------------------------  DB TEST --------------------------------------------
          // Errors
          List<Account_Staging__c> accStageErrorsList = [SELECT Action_Type__c, Error_Message__c, Account_Source__c FROM Account_Staging__c WHERE Status__c = 'Error'];
          for (Account_Staging__c accStage : accStageErrorsList) {
               System.debug('ERROR!: actionType: ' + accStage.Action_Type__c +  '@@  accERROR: ' + accStage.Error_Message__c + '@@@');
          }
          
          
     }
     
     @isTest
     static void AccountStagingTriggerHelperUpdateTest(){
          List<Account_Staging__c> accSDBList = [SELECT Id, Action_Type__c,External_Id__c FROM Account_Staging__c];
          for (Account_Staging__c accSDB : accSDBList) {
               accSDB.Status__c = 'Waiting';
          }
          update accSDBList;          

          // Errors
          List<Account_Staging__c> accStageErrorsList = [
               SELECT Action_Type__c, Error_Message__c, Account_Source__c 
               FROM Account_Staging__c 
               WHERE Status__c = 'Error'
          ];
          for (Account_Staging__c accStage : accStageErrorsList) {
               System.debug('ERROR!: actionType: ' + accStage.Action_Type__c + 
                    '@@  accERROR: ' + accStage.Error_Message__c + '@@@');
          }
     }
     
     @isTest
     static void AccountStagingTriggerHelperWrongIDTest(){
          
          List<Account_Staging__c> accSDBList = [SELECT Id, Action_Type__c,External_Id__c FROM Account_Staging__c];
          for (Account_Staging__c accSDB : accSDBList) {
               accSDB.Status__c = 'Waiting';
               accSDB.Account_Number__c = 'SOME_WRONG_ID'; // Account_Number__c is assigned to Account.Id in the trigger helper
          }
          update accSDBList;          
          
          // Errors //TODO: Should produce error in record results
          List<Account_Staging__c> accStageErrorsList = [
               SELECT Action_Type__c, Error_Message__c, Account_Source__c 
               FROM Account_Staging__c 
               WHERE Status__c = 'Error'
          ];
          for (Account_Staging__c accStage : accStageErrorsList) {
               System.debug('ERROR!: actionType: ' + accStage.Action_Type__c + 
                    '@@  accERROR: ' + accStage.Error_Message__c + '@@@');
          }
     }
     
     
     @isTest
     static void AccountStagingTriggerHelperWrongAccStageIDTest(){
          
          List<Account_Staging__c> accSDBList = [SELECT Id, Action_Type__c,External_Id__c FROM Account_Staging__c];
          for (Account_Staging__c accSDB : accSDBList) {
               accSDB.Status__c = 'Waiting';
               if (accSDB.Action_Type__c.equals('Account')) {
                    accSDB.Account_Number__c = 'SOME_WRONG_ID';
               }
               if (accSDB.Action_Type__c.equals('Contact Partner')) {
                    accSDB.Cptel2__c = 'SOME_WRONG_ID';
               }
          }
          update accSDBList;          
          
          // Errors //TODO: Should produce error in record results
          List<Account_Staging__c> accStageErrorsList = [SELECT Action_Type__c, Error_Message__c, Account_Source__c FROM Account_Staging__c WHERE Status__c = 'Error'];
          for (Account_Staging__c accStage : accStageErrorsList) {
               System.debug('ERROR!: actionType: ' + accStage.Action_Type__c +  '@@  accERROR: ' + accStage.Error_Message__c + '@@@');
          }
     }
     
     @isTest
     static void accountStagingTriggerHelperWrongAccIDTest(){
          
          Account acc = new Account(External_Id__c = 'SOME_WRONG_EX_ID', Name = 'Test Account');
          final Integer NUM_OF_ACC_STAGING_BULKS_CREATE = 1;
          final String STATUS = 'Waiting';
          List<Account_Staging__c> accStagingList = TestDataFactory_Test.createAccountStagingRecords(
               NUM_OF_ACC_STAGING_BULKS_CREATE,
               STATUS,
               'FER'
          );
          insert acc;

          insert accStagingList;
          update accStagingList;      
          
          // Errors //TODO: Should produce error in record results
          List<Account_Staging__c> accStageErrorsList = [SELECT Action_Type__c, Error_Message__c, Account_Source__c FROM Account_Staging__c WHERE Status__c = 'Error'];
          for (Account_Staging__c accStageDB : accStageErrorsList) {
               System.debug('ERROR!: actionType: ' + accStageDB.Action_Type__c +  '@@  accERROR: ' + accStageDB.Error_Message__c + '@@@');
          }
     }

     @isTest
     static void upsertRecords_Test() {
          List<Account_Staging__c> accStgs = [SELECT Id, Status__c, Action_Type__c, Account_Source__c, Sap_Number__c, Cptel2__c FROM Account_Staging__c LIMIT 10];
          List<Account> accs = [SELECT Id, Name, AccountSource, Sap_Number__c, AccountStageId__c, External_Id__c, Amfert_SAP_number__c, IBP_SAP_number__c, QAD1_sap_C__c, US_SAP_NUMBER__c, BRAZIL_SAP_NUMBER__c, Fax FROM Account];
          List<Account_Staging__c> updateAccStgs = new List<Account_Staging__c>();

          for(Integer i = 0 ; i < accs.size() ; i++){
               Integer sysAmount = AccountStagingTriggerHelper.sourceSys.size();
               Account_Staging__c accStg = new Account_Staging__c();
               accStg.Account_Source__c = accs[i].AccountSource = AccountStagingTriggerHelper.sourceSys[Math.mod(i, sysAmount)];
               accStg.Action_Type__c = 'Account';
               accStg.Account_Name__c = 'New Name ' + i;
               accStg.Fax__c = '1234567' + i;
               accStg.Business_Unit__c = 'Test Unit';
               accStg.Sap_Number__c = accs[i].Sap_Number__c;
               accStg.Status__c = 'Waiting';
               accStg.Account_Number__c = accs[i].Id;
               accStg.Country__c = 'FR';
               accStg.SAP_AccGr_text__c = 'customer';
               accStg.SAP_Account_Group__c = 'ZCNE';

               updateAccStgs.add(accStg);
          }
          insert updateAccStgs; // insert doesn't invoke the trigger (only update)

          
          Map<Id,Account_Staging__c> mUpAcc = new Map<Id,Account_Staging__c>(updateAccStgs);

          Test.startTest();
          AccountStagingTriggerHelper.upsertRecords(mUpAcc.keySet());
          Test.stopTest();
     }
}