@isTest
public with sharing class OpportunityLineItemTrigger_Test {
    @isTest
    static void testOnInsert() {
        OpportunityLineItem oli = TestDataFactory_Test.createOpportunityLineItemWithAllDependenciesForTesting();
        
        System.debug('In test OpportunityLineItem before insert: ' + oli);
        
        Test.startTest();
        Database.SaveResult res = Database.insert(oli);
        Test.stopTest();
        
        System.debug('In test OpportunityLineItem after insert: ' + oli);
        System.debug('res: ' + res);
        
        OpportunityLineItem oliFromDB = [
            SELECT
            Id,
            Name,
            UnitPrice,
            TotalPrice,
            Quantity,
            Subtotal,
            Date__c,
            Product2Id,
            Description,
            Discount,
            Month__c,
            K__c,
            N__c,
            P__c
            FROM OpportunityLineItem
        ];
        
        System.debug('oliFromDB: ' + oliFromDB);
        System.debug('res.isSuccess(): ' + res.isSuccess());
        System.debug('res.getErrors(): ' + res.getErrors());
        
        System.assert(res.isSuccess(), 'Opportunity Line Item insertion falid with error: ' + res.getErrors());
        System.assertEquals(
            797.00,
            oliFromDB.UnitPrice,
            'Somthing went wrong in the trigger or the UtilPrice calculation'
        );
    }
    
    @isTest
    static void testOnUpdate() {
        OpportunityLineItem oli = TestDataFactory_Test.createOpportunityLineItemWithAllDependenciesForTesting();
        System.debug('oli: ' + oli);
        insert oli;
            
        oli.Unit_of_measure__c='LTR';
        update oli;
        
        Product2 productDB = [SELECT Id, Mn__c FROM Product2];
        System.debug('productDB: ' + productDB);
        productDB.Mn__c = 3.5;
        
        update productDB;
        
        Product2 productDB2 = [SELECT Id, K__c FROM Product2];
        System.debug('productDB2 after change: ' + productDB2);
        
        OpportunityLineItem oliToUpdate = new OpportunityLineItem(Id = oli.Id);
        
        Test.startTest();
        Database.SaveResult res = Database.update(oliToUpdate);
        Test.stopTest();
        
        OpportunityLineItem oliFromDB = [
            SELECT
            Id,Name,UnitPrice,TotalPrice,Quantity,Subtotal,Date__c,Product2Id,Description,Discount,Month__c,K__c,N__c,P__c,FK_PriceBook__c
            FROM OpportunityLineItem
        ];
        
        System.debug('oliFromDB: ' + oliFromDB);
        System.debug('res.isSuccess(): ' + res.isSuccess());
        System.debug('res.getErrors(): ' + res.getErrors());
        
        System.assert(res.isSuccess(), 'Opportunity Line Item insertion falid with error: ' + res.getErrors());
    
    }
    
   
    
    static testmethod void  createPriceBookFromOpp(){
        
        // Create Account (alredy inserted in data factory)
        Account acc = TestDataFactory_Test.createAccountForTesting(1)[0];
        acc.Industry='לקוחות כימיקלים';
        update acc;
        // Creeate Opportunity (alredy inserted in data factory)
        Opportunity opp = TestDataFactory_Test.createOpportunityForTesting(acc);
        
        //Create Product (not inserted in data factory)
        Product2 prod = TestDataFactory_Test.createProductForTesting(1)[0];
        insert prod;
        
        // Create Price Book Entry (alredy inserted in data factory)
        PricebookEntry pbe = TestDataFactory_Test.createPriceBookEntryForTesting(prod);
        
        // Create IL_Price_Book
        IL_Price_Book__c ilpb = TestDataFactory_Test.createIlPriceBookForTesting(prod.id);
        
        OpportunityLineItem oli = TestDataFactory_Test.createOpportunityLineItemForTesting(  acc, opp,  prod, pbe);
        insert oli;
        opp.Scope__c='כימיקלים';
        opp.Status__c='Waiting for Manager Approval';
        update opp;
        
    oli.Unit_of_measure__c='M3';
        update oli;
        
        oli.Unit_of_measure__c='LTR';
        update oli;
        
          oli.Unit_of_measure__c='KG';
        update oli;
        
    }
    static testmethod void  createPriceBookFromOppKG(){
        
        // Create Account (alredy inserted in data factory)
        Account acc = TestDataFactory_Test.createAccountForTesting(1)[0];
        acc.Industry='לקוחות כימיקלים';
        update acc;
        // Creeate Opportunity (alredy inserted in data factory)
        Opportunity opp = TestDataFactory_Test.createOpportunityForTesting(acc);
        
        //Create Product (not inserted in data factory)
        Product2 prod = TestDataFactory_Test.createProductForTesting(1)[0];
        insert prod;
        
        // Create Price Book Entry (alredy inserted in data factory)
        PricebookEntry pbe = TestDataFactory_Test.createPriceBookEntryForTesting(prod);
        
        // Create IL_Price_Book
        IL_Price_Book__c ilpb = TestDataFactory_Test.createIlPriceBookForTesting(prod.id);
        
        OpportunityLineItem OLI = TestDataFactory_Test.createOpportunityLineItemForTesting(  acc, opp,  prod, pbe);
        OLI.Unit_of_measure__c='KG';
        insert OLI;
        opp.Scope__c='כימיקלים';
        opp.Status__c='Waiting for Manager Approval';
        update opp;
        
    }
    static testmethod void  createPriceBookFromOppM3(){
        
        // Create Account (alredy inserted in data factory)
        Account acc = TestDataFactory_Test.createAccountForTesting(1)[0];
        acc.Industry='לקוחות כימיקלים';
        update acc;
        // Creeate Opportunity (alredy inserted in data factory)
        Opportunity opp = TestDataFactory_Test.createOpportunityForTesting(acc);
        
        //Create Product (not inserted in data factory)
        Product2 prod = TestDataFactory_Test.createProductForTesting(1)[0];
        insert prod;
        
        // Create Price Book Entry (alredy inserted in data factory)
        PricebookEntry pbe = TestDataFactory_Test.createPriceBookEntryForTesting(prod);
        
        // Create IL_Price_Book
        IL_Price_Book__c ilpb = TestDataFactory_Test.createIlPriceBookForTesting(prod.id);
        
        OpportunityLineItem OLI = TestDataFactory_Test.createOpportunityLineItemForTesting(  acc, opp,  prod, pbe);
        OLI.Unit_of_measure__c='M3';
        insert OLI;
        opp.Scope__c='כימיקלים';
        opp.Status__c='Waiting for Manager Approval';
        update opp;
        
    }
    
    
    static testmethod void  createFertilizePlan(){
        
        // Create Account (alredy inserted in data factory)
        Account acc = TestDataFactory_Test.createAccountForTesting(1)[0];
        acc.Industry='לקוחות כימיקלים';
        update acc;
        // Creeate Opportunity (alredy inserted in data factory)
        Opportunity opp = TestDataFactory_Test.createOpportunityForTesting(acc);
        opp.RecordTypeId=[SELECT Id FROM RecordType  WHERE Name='Fertilize Plan'].Id;
        update opp;
        
        //Create Product (not inserted in data factory)
        Product2 prod = TestDataFactory_Test.createProductForTesting(1)[0];
        insert prod;
        
        // Create Price Book Entry (alredy inserted in data factory)
        PricebookEntry pbe = TestDataFactory_Test.createPriceBookEntryForTesting(prod);
        
        // Create IL_Price_Book
        IL_Price_Book__c ilpb = TestDataFactory_Test.createIlPriceBookForTesting(prod.id);
        
        OpportunityLineItem OLI = TestDataFactory_Test.createOpportunityLineItemForTesting(  acc, opp,  prod, pbe);
        insert OLI;
        
    }
}