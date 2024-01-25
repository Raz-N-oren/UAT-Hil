@isTest
public with sharing class SalesInformationTrigger_Test {
    @isTest
    static void BeforeInsert_Test() {
        // Create sales_Information records and the related Accounts & Products (not inserted so can't be created in @TestSetup)
        final Integer REQ_AMOUNT = 4 * AccountStagingTriggerHelper.sourceSys.size();
        List<Sales_Information__c> salesInfos = 
            TestDataFactory_Test.createAndInsertSalesInformationWithRelationsForTesting(REQ_AMOUNT);

        // Check insertion with invalid External Id (all SalesInfos should be created)
        salesInfos[0].Ship_To_SAP_Number__c = 'Not_Existing_SAP_Number';

        Test.startTest();
        // insert the salesInformation records
        insert salesInfos;
        Test.stopTest();

        List<Sales_Information__c> salesInfosFromDB = [
            SELECT Name, Source_System__c, Product_SAP_Nmuber__c, Product__c, Ship_To_SAP_Number__c, Ship_To_Account__c, 
            Sold_To_Sap_Number__c, Sold_To_Account__c, Total_Price__c
            FROM Sales_Information__c
        ];

        // Chack that all SalesInfos created even thow one ShipToSapNumber is missing
        System.assertEquals(REQ_AMOUNT, salesInfosFromDB.size() , 'Not all "Sales Information" records created!');
    }

    @isTest
    static void BeforeUpdate_Test() {
        // Create sales_Information records and the related Accounts & Products
        final Integer REQ_AMOUNT = 4 * AccountStagingTriggerHelper.sourceSys.size();
        List<Sales_Information__c> salesInfos = 
            TestDataFactory_Test.createAndInsertSalesInformationWithRelationsForTesting(REQ_AMOUNT);
            
        String tempExIdHolder = salesInfos[0].Ship_To_SAP_Number__c;
        salesInfos[0].Ship_To_SAP_Number__c = 'Not_Existing_SAP_Number';
        // System.debug('Before insert');
        insert salesInfos;
        
        salesInfos[0].Ship_To_SAP_Number__c = tempExIdHolder;
        Test.startTest();
        // Check insertion with invalid External Id
        // insert the salesInformation records
        // Fix the invalid External Id and test the 'before apdate'
        update salesInfos;
        Test.stopTest();

        List<Sales_Information__c> salesInfosFromDB = [
            SELECT Name, Source_System__c, Product_SAP_Nmuber__c, Product__c, Ship_To_SAP_Number__c, Ship_To_Account__c, 
            Sold_To_Sap_Number__c, Sold_To_Account__c, Total_Price__c
            FROM Sales_Information__c
        ];

        System.assertEquals(REQ_AMOUNT, salesInfosFromDB.size() , 'Not all "Sales Information" records created!');
        for(Sales_Information__c si : salesInfosFromDB){
            // Check all lookups created
            System.assertNotEquals(null, si.Product__c, 'Product Lookup have not been created!');
            System.assertNotEquals(null, si.Ship_To_Account__c, '\'Ship To Account\' Lookup have been not created!');
            System.assertNotEquals(null, si.Sold_To_Account__c, '\'Sold To Account\' Lookup have been not created!');
        }
    }
}