@isTest
public with sharing class ProductStagingTriggerHelper_Test {
    // TODO: Write test for high volume insert operations
    @isTest
    public static void ConvertRatioTest() {
        //TODO: ## IMPORTANT ## --> uncomment commented assertions
        final String RATIO_CONVERT_ERROR_MESSAGE = 'Returned ratio String is not mathing the expected';
        
        //NPKratio__c ==> convertRatio(N,P,K)
        String ratioNPK1 = ProductStagingTriggerHelper.convertRatio(Integer.valueOf(3),Integer.valueOf(3),Integer.valueOf(3));
        System.assertEquals('1-1-1', ratioNPK1, RATIO_CONVERT_ERROR_MESSAGE);
        String ratioNPK2 = ProductStagingTriggerHelper.convertRatio(Integer.valueOf(1),Integer.valueOf(3),Integer.valueOf(0));
        System.assertEquals('1-3-0', ratioNPK2, RATIO_CONVERT_ERROR_MESSAGE);
        String ratioNPK3 = ProductStagingTriggerHelper.convertRatio(Integer.valueOf(3),Integer.valueOf(9),Integer.valueOf(3));
        System.assertEquals('1-3-1', ratioNPK3, RATIO_CONVERT_ERROR_MESSAGE);
        String ratioNPK4 = ProductStagingTriggerHelper.convertRatio(Integer.valueOf(2),Integer.valueOf(5),Integer.valueOf(0));
        System.assertEquals('2-5-0', ratioNPK4, RATIO_CONVERT_ERROR_MESSAGE);
        String ratioNPK5 = ProductStagingTriggerHelper.convertRatio(Integer.valueOf(2),Integer.valueOf(2),Integer.valueOf(0)); 
        System.assertEquals('1-1-0', ratioNPK5, RATIO_CONVERT_ERROR_MESSAGE);
        String ratioNPK6 = ProductStagingTriggerHelper.convertRatio(Integer.valueOf(0),Integer.valueOf(0),Integer.valueOf(0)); 
        System.assertEquals('0-0-0', ratioNPK6, RATIO_CONVERT_ERROR_MESSAGE);
        String ratioNPK7 = ProductStagingTriggerHelper.convertRatio(Integer.valueOf(4),Integer.valueOf(0),Integer.valueOf(4)); 
        System.assertEquals('1-0-1', ratioNPK7, RATIO_CONVERT_ERROR_MESSAGE);
        String ratioNPK8 = ProductStagingTriggerHelper.convertRatio(Integer.valueOf(2),Integer.valueOf(0),Integer.valueOf(5)); 
        System.assertEquals('2-0-5', ratioNPK8, RATIO_CONVERT_ERROR_MESSAGE);
        String ratioNPK9 = ProductStagingTriggerHelper.convertRatio(Integer.valueOf(1),Integer.valueOf(0),Integer.valueOf(5)); 
        System.assertEquals('1-0-5', ratioNPK9, RATIO_CONVERT_ERROR_MESSAGE);
        
        //NPratio__c ==> convertRatio(N,P,null);
        String ratioNP1 = ProductStagingTriggerHelper.convertRatio(Integer.valueOf(3),Integer.valueOf(3),null);
        System.assertEquals('1-1', ratioNP1, RATIO_CONVERT_ERROR_MESSAGE);
        String ratioNP2 = ProductStagingTriggerHelper.convertRatio(Integer.valueOf(2),Integer.valueOf(5),null);
        System.assertEquals('2-5', ratioNP2, RATIO_CONVERT_ERROR_MESSAGE);
        String ratioNP3 = ProductStagingTriggerHelper.convertRatio(Integer.valueOf(1),Integer.valueOf(3),null);
        System.assertEquals('1-3', ratioNP3, RATIO_CONVERT_ERROR_MESSAGE);
        String ratioNP4 = ProductStagingTriggerHelper.convertRatio(Integer.valueOf(0),Integer.valueOf(3),null); 
        System.assertEquals('0-1', ratioNP4, RATIO_CONVERT_ERROR_MESSAGE);
        String ratioNP5 = ProductStagingTriggerHelper.convertRatio(Integer.valueOf(3),Integer.valueOf(0),null); 
        System.assertEquals('1-0', ratioNP5, RATIO_CONVERT_ERROR_MESSAGE);
        String ratioNP6 = ProductStagingTriggerHelper.convertRatio(Integer.valueOf(0),Integer.valueOf(0),null);
        System.assertEquals('0-0', ratioNP6, RATIO_CONVERT_ERROR_MESSAGE);
        String ratioNP7 = ProductStagingTriggerHelper.convertRatio(Integer.valueOf(1),Integer.valueOf(0),null);
        System.assertEquals('1-0', ratioNP7, RATIO_CONVERT_ERROR_MESSAGE);
        String ratioNP8 = ProductStagingTriggerHelper.convertRatio(Integer.valueOf(2),Integer.valueOf(4),null);
        System.assertEquals('1-2', ratioNP8, RATIO_CONVERT_ERROR_MESSAGE);
 
         
        String ratioNP9 = ProductStagingTriggerHelper.convertRatio(Integer.valueOf(6),Integer.valueOf(8),Integer.valueOf(8));
        System.assertEquals('3-4-4', ratioNP9, RATIO_CONVERT_ERROR_MESSAGE);
        String ratioNP11 = ProductStagingTriggerHelper.convertRatio(Integer.valueOf(8),Integer.valueOf(6),Integer.valueOf(6));
        System.assertEquals('4-3-3', ratioNP11, RATIO_CONVERT_ERROR_MESSAGE);
        String ratioNP10 = ProductStagingTriggerHelper.convertRatio(Integer.valueOf(6),Integer.valueOf(8),null);
        System.assertEquals('3-4', ratioNP10, RATIO_CONVERT_ERROR_MESSAGE);
        String ratioNP12 = ProductStagingTriggerHelper.convertRatio(Integer.valueOf(3),Integer.valueOf(4),null);
        System.assertEquals('3-4', ratioNP12, RATIO_CONVERT_ERROR_MESSAGE);
        String ratioNP13 = ProductStagingTriggerHelper.convertRatio(Integer.valueOf(9),Integer.valueOf(12),null);
        System.assertEquals('3-4', ratioNP13, RATIO_CONVERT_ERROR_MESSAGE);
        
        
    }
    
    @isTest
    public static void OnlyStatusWaytingForwardedToInsideProductsToUpsertList() { 
        
        //TODO: remove unused variables
        //TODO: ## important ## --> uncomment assertions

        // Takes 'Product_Staging__c' elements from test THEN upserting with the 'Product2' elements in DB based on shared externalID
        // TEST DESCRIPTION: Asserts only 'Product_Staging__c' elements with status 'Waiting' are passing on to the upserting process
        
        ///Product_staging parameters  
        final Integer NUM_OF_PRODUCT_STAGING_TO_CREATE = 50;
        final String STATUS_WAITING = 'Waiting';
        final String EXTENSION_EXID_SUFFIX = 'demoextension';
        final String MASTERPROD_EXID_SUFFIX = 'demomaster';
        final String SOURCE_SYSTEM = 'AMF';
        final Integer SET_AMOUNT_STATUS_DIFF_THEN_WAITING = 10;
        final String SAP_NUMBER = 'sapnumber';  
        
        //Product2 parametrs
        final Integer NUM_OF_PRODUCT2_TO_CREATE = 50; //should be the as NUM_OF_PRODUCT_STAGING_TO_CREATE for successful test
        final String PROD2_PROD_EXID = SOURCE_SYSTEM + SAP_NUMBER;
        final String PROD2_MASTER_EXID = SOURCE_SYSTEM + MASTERPROD_EXID_SUFFIX;
        final String PROD2_EXTENSION_EXID = SOURCE_SYSTEM + EXTENSION_EXID_SUFFIX;
        
        
        // -------   Creates and add to DB Product2 elemetns with manual External IDs to be Matched by the ProductStaging elements in  processProductsUpsert() --------   
        TestDataFactory_Test.createProduct2Records(
        NUM_OF_PRODUCT2_TO_CREATE,
        PROD2_PROD_EXID,
        PROD2_MASTER_EXID,
        PROD2_EXTENSION_EXID
        );
        
        // Create and  inserts the Product_Staging__c to invoke the trigger that intiate the ProductStaging upserting process
        TestDataFactory_Test.createProductStagingRecords(
        NUM_OF_PRODUCT_STAGING_TO_CREATE,
        STATUS_WAITING,
        SOURCE_SYSTEM,
        EXTENSION_EXID_SUFFIX,
        MASTERPROD_EXID_SUFFIX,
        SET_AMOUNT_STATUS_DIFF_THEN_WAITING,
        SAP_NUMBER);
        Test.startTest();
        
        // Trigger should ADD all new or updated 'Product_Staging__c' Objects with status "Waiting" to productsToUpsert() list
        Test.stopTest();
        
        
        
        /* As the upserting process is setting Status value which indicates Failure/Success for all the incoming Product_Staging elemnts
        Gets all Product_Staging__c with status == 'Success' */
        
        List <Product_Staging__c> proStageStatusErrorsList = [SELECT Id ,Error_Message__c  FROM Product_Staging__c WHERE Status__c = 'Error'];
        List <Product_Staging__c> proStageStatusSuccessList = [SELECT Id ,Error_Message__c  FROM Product_Staging__c WHERE Status__c = 'Success'];
        
        //TODO: ## IMPORTANT ## --> uncomment assertions
        // System.assertEquals(NUM_OF_PRODUCT_STAGING_TO_CREATE - SET_AMOUNT_STATUS_DIFF_THEN_WAITING, proStageStatusSuccessList.size(), 'Quantity amount for Product2 element with Status == \'Success\' is not expected');
       // System.assertEquals( 10  , proStageStatusErrorsList.size(), 'Eror was found but was not expected');   
        
        
    }
    
    
    @isTest
    public static void noMatchingForSomeExternalIdsOfIncomingProductStaginRecord(){ 
        //TODO: remove unused variables
        //TODO: ## important ## --> remove commented assertion
        
        
        // Takes 'Product_Staging__c' elements from test THEN upserting with the 'Product2' elements in DB based on shared externalID
        // TEST DESCRIPTION: Asserts thats 'Product_Staging__c' elements are actualy upserting with Product2 elemetns (in particular property 'Product_Name__c'\'Name' 
        
        ///Product_staging parameters  
        final Integer NUM_OF_PRODUCT_STAGING_TO_CREATE = 55;
        final String STATUS_WAITING = 'Waiting';
        final String EXTENSION_EXID_SUFFIX = 'demoextension';
        final String MASTERPROD_EXID_SUFFIX = 'demomaster';
        final String SOURCE_SYSTEM = 'AMF';
        final Integer SET_AMOUNT_STATUS_DIFF_THEN_WAITING = 0;
        final String SAP_NUMBER = 'sapnumber';  
        
        //Product2 parametrs
        final Integer NUM_OF_PRODUCT2_TO_CREATE = 50; //should be the as NUM_OF_PRODUCT_STAGING_TO_CREATE for successful test
        final String PROD2_PROD_EXID = SOURCE_SYSTEM + SAP_NUMBER;
        final String PROD2_MASTER_EXID = SOURCE_SYSTEM + MASTERPROD_EXID_SUFFIX;
        final String PROD2_EXTENSION_EXID = SOURCE_SYSTEM + EXTENSION_EXID_SUFFIX;
        
        
        // -------   Creates and add to DB Product2 elemetns with manual External IDs to be Matched by the ProductStaging elements in  processProductsUpsert() --------   
        List<Product2> prod2ToInsertList = TestDataFactory_Test.createProduct2Records(
        NUM_OF_PRODUCT2_TO_CREATE,
        PROD2_PROD_EXID,
        PROD2_MASTER_EXID,
        PROD2_EXTENSION_EXID
        );
        
        
        // Create and  inserts the Product_Staging__c to invoke the trigger that intiate the ProductStaging upserting process
        List<Product_Staging__c> prodStagingToInsertList = TestDataFactory_Test.createProductStagingRecords(
        NUM_OF_PRODUCT_STAGING_TO_CREATE,
        STATUS_WAITING,
        SOURCE_SYSTEM,
        EXTENSION_EXID_SUFFIX,
        MASTERPROD_EXID_SUFFIX,
        SET_AMOUNT_STATUS_DIFF_THEN_WAITING,
        SAP_NUMBER);
        Test.startTest();
        
        // Trigger should ADD all new or updated 'Product_Staging__c' Objects with status "Waiting" to productsToUpsert() list
        Test.stopTest();
        
        List <Product_Staging__c> proStageStatusErrorsList = [SELECT Id ,Error_Message__c, Product_Name__c   FROM Product_Staging__c WHERE Status__c = 'Error'];
        List <Product_Staging__c> proStageStatusSuccessList = [SELECT Id ,Error_Message__c  FROM Product_Staging__c WHERE Status__c = 'Success'];
        List <Product2> pro2List = [SELECT Name, External_ID__c, Extension_1__c, Master_product__c FROM Product2 WHERE Name != 'Demo extension' AND Name != 'Demo masterProduct'];
        
        // asserts Product2 'Name' property in DB was updated to 'Product_Name__c' from the incoming 'Product_Staging__c' elements
       /* TODO: uncomment
        for (Integer i = 0; i < prodStagingToInsertList.size(); i++) {
            String proStageName = prodStagingToInsertList[i].Product_Name__c;
            String product2Name = pro2List[i].Name;
            
             System.assertEquals( proStageName , product2Name);
        }
        */
        
    }
    
    @isTest
    public static void noMatchingExternalIdInProduct2ForExtenstionOrMasterProduct(){ 
        //TODO: ## important ## --> remove commented assertions
        //TODO: remove unused variables
        
        // Takes 'Product_Staging__c' elements from test THEN upserting with the 'Product2' elements in DB based on shared externalID
        // TEST DESCRIPTION: Asserts thats the proper error is invoked when there is no match for Product staging external IDs
        
        ///Product_staging parameters  
        final Integer NUM_OF_PRODUCT_STAGING_TO_CREATE = 50;
        final String STATUS_WAITING = 'Waiting';
        final String DELIBERATLY_NULL_EXID_SUFFIX = 'null'; // Deliberately equals to 'null' for producing error in this test 
        final String SOURCE_SYSTEM = 'amf';
        final Integer SET_AMOUNT_STATUS_DIFF_THEN_WAITING = 0;
        final String SAP_NUMBER = 'sapnumber';  
        
        //Product2 parametrs
        final Integer NUM_OF_PRODUCT2_TO_CREATE = 50; //should be the as NUM_OF_PRODUCT_STAGING_TO_CREATE for successful test
        final String PROD2_PROD_EXID = SOURCE_SYSTEM + SAP_NUMBER;
        final String PROD2_MASTER_EXID = SOURCE_SYSTEM + DELIBERATLY_NULL_EXID_SUFFIX;
        final String PROD2_EXTENSION_EXID = SOURCE_SYSTEM + DELIBERATLY_NULL_EXID_SUFFIX;
        
        
        // -------   Creates and add to DB Product2 elemetns with manual External IDs to be Matched by the ProductStaging elements in  processProductsUpsert() --------   
        List<Product2> prod2ToInsertList = TestDataFactory_Test.createProduct2Records(
        NUM_OF_PRODUCT2_TO_CREATE,
        PROD2_PROD_EXID,
        PROD2_MASTER_EXID,
        PROD2_EXTENSION_EXID
        );
        
        
        // Create and  inserts the Product_Staging__c to invoke the trigger that intiate the ProductStaging upserting process
        List<Product_Staging__c> prodStagingToInsertList = TestDataFactory_Test.createProductStagingRecords(
        NUM_OF_PRODUCT_STAGING_TO_CREATE,
        STATUS_WAITING,
        SOURCE_SYSTEM,
        DELIBERATLY_NULL_EXID_SUFFIX,
        DELIBERATLY_NULL_EXID_SUFFIX,
        SET_AMOUNT_STATUS_DIFF_THEN_WAITING,
        SAP_NUMBER);
        Test.startTest();
        
        // Trigger should ADD all new or updated 'Product_Staging__c' Objects with status "Waiting" to productsToUpsert() list
        Test.stopTest();
            
            List <Product_Staging__c> proStageStatusSuccessList = [SELECT Id ,Error_Message__c  FROM Product_Staging__c WHERE Status__c = 'Success'];
            List <Product_Staging__c> proStageStatusErrorsList = [SELECT Id ,Error_Message__c, Product_Name__c   FROM Product_Staging__c WHERE Status__c = 'Error'];
            List <Product_Staging__c> proStageList = [SELECT Id ,Error_Message__c  FROM Product_Staging__c];
            List <Product2> pro2List = [SELECT Name, External_ID__c, Extension_1__c, Master_product__c FROM Product2];
            
            /* TODO: uncomment assertions
            for (Product_Staging__c prodStage : proStageList) {
                System.assertEquals(  'Foreign key external ID: ' + SOURCE_SYSTEM + DELIBERATLY_NULL_EXID_SUFFIX + ' not found for field External_Id__c in entity Product2' , prodStage.Error_Message__c);
            }
                System.assertEquals( NUM_OF_PRODUCT2_TO_CREATE, proStageStatusErrorsList.size());
                */
        }
        
        
        
    }