@isTest
public class discountDetailsController_Test {
    
    public static testmethod void getProductDiscountRangeTest(){
        test.startTest();
        Account acc =TestDataFactory_Test.createAccountForTesting(20)[0];
        discountDetailsController.getAccountClassification(acc.Id);
        discountDetailsController.getProductDiscountRange(acc.Id);
        discountDetailsController.getProductFamilyDiscountRange(acc.Id);
        test.stopTest();
        
    }
    
    public static testmethod void getPriceForProductTest(){
        test.startTest();
        Account acc =TestDataFactory_Test.createAccountForTesting(20)[0];
        //create productHier
        Product_hierarchy__c ph= TestDataFactory_Test.createMasterProducthierarchy();
        //create product
        Product2 prod =TestDataFactory_Test.createProductForTesting(1)[0];
        prod.Product_hierarchy__c=ph.Id;
        insert prod;
        // Create Price Book Entry (alredy inserted in data factory)
        PricebookEntry pbe = TestDataFactory_Test.createPriceBookEntryForTesting(prod);
        // Create IL_Price_Book
        IL_Price_Book__c ilpb = TestDataFactory_Test.createIlPriceBookForTesting(prod.id);
        discountDetailsController.getPriceForProduct(prod.Id, acc.Id);
        discountDetailsController.getProductGravity(prod.Id);
        discountDetailsController.getMatrixLineInfo(acc.Id, prod.Id, ph.Id);

        test.stopTest();
        
    }
        public static testmethod void getPriceForProductNoPBTest(){
        test.startTest();
        Account acc =TestDataFactory_Test.createAccountForTesting(20)[0];
        //create productHier
        Product_hierarchy__c ph= TestDataFactory_Test.createMasterProducthierarchy();
        //create product
        Product2 prod =TestDataFactory_Test.createProductForTesting(1)[0];
        prod.Product_hierarchy__c=ph.Id;
        insert prod;
        // Create Price Book Entry (alredy inserted in data factory)
        PricebookEntry pbe = TestDataFactory_Test.createPriceBookEntryForTesting(prod);
        discountDetailsController.getPriceForProduct(prod.Id, acc.Id);
            
           
        getProductDiscount.upsertRelaventDeliveryNotes( TestDataFactory_Test.createNewDiscount(acc.Id, prod.Id));
        test.stopTest();
        
    }
    
}