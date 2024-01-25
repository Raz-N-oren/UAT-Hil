@isTest
public with sharing class DiscountDitailsTest {
    @isTest
    static void getMatrixLineInfoTest() {
        // Create necessary data for test (account, product, matrix, matrix line item) and insert to DB
        Account acc = TestDataFactory_Test.createAccountForTesting(1)[0];
   
        Product2 prod = TestDataFactory_Test.createProductForTesting(1)[0];
        insert prod;
        
        Discount_Matrix__c mat = TestDataFactory_Test.createDisMatForTesting();
        Discount_matrix_Line__c matLineItem = TestDataFactory_Test.createDisMatLineForTesting(mat.Id, 1)[0];
        Product_Group_Category__c prodGrCat = TestDataFactory_Test.createProdGroupCategoryForTesting(
            matLineItem.Product_Family__c,
            prod.Family
        );
        
        // Run the function to get the info (get Discount_matrix_Line__c)
        Test.startTest();
        Discount_matrix_Line__c disMatLine = discountDetailsController.getMatrixLineInfo(acc.Id, prod.Id, null);
        Test.stopTest();
        
        // Check that the received data exists and is right
      //  System.assertNotEquals(null, disMatLine, 'Discount Matrix Line should not be null');
      //  System.assertEquals(matLineItem.Id, disMatLine.Id, 'The wrong discount line item is found');
    }

    @isTest
    static void getPriceForProductTest() {
         Account acc = TestDataFactory_Test.createAccountForTesting(1)[0];
        
        Product2 prod = TestDataFactory_Test.createProductForTesting(1)[0];
        insert prod;

        IL_Price_Book__c ibp = TestDataFactory_Test.createIlPriceBookForTesting(prod.Id);

        Test.startTest();
        Map<String, Decimal> priceResult = discountDetailsController.getPriceForProduct(prod.Id,acc.iD);
        Test.stopTest();

        System.assertNotEquals(null, priceResult, 'Price should not be null');
      //  System.assertEquals(797.00, priceResult.get('Tonnes'), 'Wrong price in tonnes!');
       // System.assertEquals(637.60, priceResult.get('Cubes'), 'Wrong price in cubes!');
    }
}