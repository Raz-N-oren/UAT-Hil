@isTest
public with sharing class SampleDataTrigger_Test {
    // Test 'lab test result' creation.
    @isTest
    public static void labTestResultsCreationTest() {
        Account acc = TestDataFactory_Test.createAccountForTesting(1)[0];
        Lab_Test__c lt = TestDataFactory_Test.createLabTestForTesting(acc.id);

        // Create static objects records
        TestDataFactory_Test.createStaticObjectsRecordsForTesting();

        Test.startTest();
        Sample_data__c sd = TestDataFactory_Test.createSampleDataForTesting(acc.id, lt.id);
        Test.stopTest();

        Integer labTestResFromTest = [SELECT COUNT() FROM Lab_Test_Results__c];
        System.assertEquals(2, labTestResFromTest, 'Wrong amount of "lab test result" records have been created');
    }

    // Test 'sample data' update that affects 'lab test results'
    @isTest
    public static void labTestResultsUpdateTest() {
        Account acc = TestDataFactory_Test.createAccountForTesting(1)[0];
        Lab_Test__c lt = TestDataFactory_Test.createLabTestForTesting(acc.id);

        // Create static objects records
        TestDataFactory_Test.createStaticObjectsRecordsForTesting();

        Sample_data__c sd = TestDataFactory_Test.createSampleDataForTesting(acc.id, lt.id);
        sd.pH__c = true;
        sd.Fe__c = true;
        sd.SP__c = false;

        Test.startTest();
        update sd;
        Test.stopTest();

        Integer labTestResFromTest = [SELECT COUNT() FROM Lab_Test_Results__c];
        System.assertEquals(3, labTestResFromTest, 'Wrong amount of "lab test result" records have been created');
    }

    // Test 'sample data' update after the test been sent to the laboratory
    @isTest
    public static void updateAfterSentToLabTest() {
        Account acc = TestDataFactory_Test.createAccountForTesting(1)[0];
        Lab_Test__c lt = TestDataFactory_Test.createLabTestForTesting(acc.id);

        // Create static objects records
        TestDataFactory_Test.createStaticObjectsRecordsForTesting();

        Sample_data__c sd = TestDataFactory_Test.createSampleDataForTesting(acc.id, lt.id);

        // Change the test status to 'sent to lab' before the 'sample data changes'
        lt.Status__c = 'נשלח למעבדה';
        update lt;

        sd.pH__c = true;
        sd.K2O__c = true;
        sd.SP__c = false;

        Test.startTest();
        update sd;
        Test.stopTest();

        Integer labTestResFromTest = [SELECT COUNT() FROM Lab_Test_Results__c];
        System.assertEquals(2, labTestResFromTest, 'Wrong amount of "lab test result" records have been created');
    }
}