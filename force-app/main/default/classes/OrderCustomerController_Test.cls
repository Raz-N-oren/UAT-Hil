@isTest
public class OrderCustomerController_Test {
    @testSetup static void createData(){        
        LoadingPoint__c LP= TestDataFactory_Test.createLoadingPoint('ספק');
        DefaultLoadingPoint__c defaultLP    = new DefaultLoadingPoint__c();
        defaultLP.LoadingPointId__c=LP.Id;
        insert defaultLP;
        Account acc                         = TestDataFactory_Test.createAccountForTesting(20)[0];
        //create productHier
        Product_hierarchy__c ph             = TestDataFactory_Test.createMasterProducthierarchy();
        //create product
        Product2 prod                       = TestDataFactory_Test.createProductForTesting(1)[0];
        prod.Product_hierarchy_Code__c      = ph.External_ID__c;
        prod.Name                           = 'test1';
        insert prod;
        //Create Price Book Entry (alredy inserted in data factory)
        PricebookEntry pbe                  = TestDataFactory_Test.createPriceBookEntryForTesting(prod);
        //Create IL_Price_Book
        IL_Price_Book__c ilpb               = TestDataFactory_Test.createIlPriceBookForTesting(prod.id);
        order orderRec                      = TestDataFactory_Test.createOrder();
        order orderRec1                     = TestDataFactory_Test.createOrder();

        orderItem orderItemRec              = TestDataFactory_Test.createOrderItem(orderRec,ph.Id, LP.Id);
        Branch_growth__c branch             = TestDataFactory_Test.createBranchGrowthForTesting(acc);
    }
    
    public static testmethod void FrameOrder_Test(){
        test.startTest();
        order orderFrameRec         = [SELECT Id,TransactionType__c,accountId FROM order  LIMIT 1];
        orderItem orderItemFrameRec = [SELECT Id,TransactionType__c,DischargeLocation__c,PricebookEntryId, Product2Id, Quantity,Product2.Product_hierarchy__c,LoadingPoint__c, framework_agreement_Usege_Quntity__c FROM orderItem  LIMIT 1];
        
        order orderRec              = TestDataFactory_Test.createOrder();
        orderRec.TransactionType__c = '70';
        orderRec.AccountId          = orderFrameRec.AccountId;
        update orderRec;
        
       orderItem orderItemRec =new orderItem(
            orderId=orderRec.Id,
            DischargeLocation__c=orderItemFrameRec.DischargeLocation__c,
            LoadingPoint__c=orderItemFrameRec.LoadingPoint__c,
            PricebookEntryId=orderItemFrameRec.PricebookEntryId,
            Product2Id=orderItemFrameRec.Product2Id,
            Quantity=8,
            Status__c='10',
            UnitOfMeasure__c='TO',
            UnitPrice=0
        );
        insert orderItemRec;
        
        List<SObject> result = OrderCustomerController.isFramDealExit(orderFrameRec.AccountId,orderItemRec.Product2Id);
        system.assertEquals(1, result.size());
        OrderCustomerController.isFramDealExit(orderFrameRec.AccountId, orderItemRec.Product2Id);
        OrderCustomerController.getFramDealDetails(orderFrameRec.AccountId, orderItemRec.Product2Id);
        OrderCustomerController.updateOrderAndOrderItemStatusNew(orderRec.Id,orderItemFrameRec.Id);
        test.stopTest();
    }
    
    public static testmethod void productInformation_Test(){
        test.startTest();
        product2 prod               = [SELECT Id,Name,Product_hierarchy__c,Product_hierarchy__r.Name FROM product2 WHERE Product_hierarchy__c!=NULL LIMIT 1];
        order orderRec              = [SELECT Id,accountId FROM order WHERE TransactionType__c='30' LIMIT 1];
        order orderRec1             = [SELECT Id,accountId FROM order WHERE TransactionType__c='30' LIMIT 1 ];
        
        Account acc                 = [SELECT Id,Name FROM Account limit 1];
        Branch_growth__c branch     = [SELECT Id FROM Branch_growth__c limit 1];
        Id LP 						= OrderCustomerController.getDefaultLP();
        orderItem orderItemRec = [SELECT Id,TransactionType__c,DischargeLocation__c,PricebookEntryId, Product2Id, Quantity,Product2.Product_hierarchy__c,LoadingPoint__c, framework_agreement_Usege_Quntity__c FROM orderItem  LIMIT 1];

        
        
        OrderCustomerController.searchAccountNameMethod(acc.Name);
        OrderCustomerController.isFcSubAdmin();
        OrderCustomerController.recentlyViewRecords(); 
        OrderCustomerController.forViewAccount(acc.Id);
        OrderCustomerController.getPreviousOrdersPayerAgentAndWarehouseForAccount(acc.Id);
        OrderCustomerController.getContactsForAccount(acc.Id);
        OrderCustomerController.getWarehousePhone(acc.Id);
        OrderCustomerController.getNotesToAccount(acc.Id);
        OrderCustomerController.getAccountAndContacts(acc.Id);
        OrderCustomerController.getParentAccount(branch.id);
        OrderCustomerController.getContactsForBranch(branch.id);
        OrderCustomerController.getOrderAndOrderItems(orderRec.Id);
        OrderCustomerController.getOrderItemsById(orderRec.Id);
        OrderCustomerController.getSalesPoints();
        OrderCustomerController.getTankPoints(acc.Id);
        OrderCustomerController.getLastOrdersForAccount(orderRec.Id,2);
        OrderCustomerController.getUserProfile(userInfo.getUserId());
        OrderCustomerController.getMasterProduct(prod.Product_hierarchy__r.Name);
        OrderCustomerController.getProductById(prod.id);
        OrderCustomerController.isProductChosen(orderRec.Id,prod.id);
        OrderCustomerController.getPricebookEntryId(prod.id);
        OrderCustomerController.searchProductByNameMethod(prod.Name);
        OrderCustomerController.getRelatedLoadingPoint('חיפה כימיקלים דרום'+'ספק');
        OrderCustomerController.getParent(orderRec.accountId);
        OrderCustomerController.searchProductByNameAndMasterProductMethod(prod.Name,prod.Product_hierarchy__r.Name);
        OrderCustomerController.isHazardMaterial(prod.id);
        OrderCustomerController.calculateBH(system.today());
        OrderCustomerController.updateTankStatus(orderItemRec.DischargeLocation__c);

        OrderCustomerController.isBH(system.today());
        test.stopTest();
    }
}