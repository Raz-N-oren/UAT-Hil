@isTest
public class YearlyPlanEmailByPlotsController_Test {
    
    // Static values for assertions
    private static final Decimal OPP_LINE1_N = 2;
    private static final Decimal OPP_LINE1_P = 3;
    private static final Decimal OPP_LINE1_K = 4;
    private static final Decimal OPP_LINE2_N = 1;
    private static final Decimal OPP_LINE2_P = 2;
    private static final Decimal OPP_LINE2_K = 3;
    private static final Decimal OPP_LINE1_QUANTITY = 1;
    private static final Decimal OPP_LINE3_QUANTITY = 2;
    
    /*
    ## This test is testing the controller for the component of the visualforce email template ##
    
    # Creates Opportunity to hold diffrent kind of oppertunityLineItems
    # Creates OppLineItems and relate them  to diffrent products who have diffrent values (Like diffrent name and Etc.)
    # NOTE: PriceBookEntry effects the product type of the opportunityLineItem
    
    */
    @TestSetup
    static void makeData(){
        final Integer NUM_OF_ACCOUNTS_TO_CREATE = 1;
        Account acc = TestDataFactory_Test.createAccountForTesting(NUM_OF_ACCOUNTS_TO_CREATE)[0];
        
        Product2 prod1 = new Product2(Name = 'Product1', isActive = true);
        insert prod1;
        Product2 prod2 = new Product2(Name = 'Product2', isActive = true);
        insert prod2;
        
        Opportunity opp = TestDataFactory_Test.createOpportunityForTesting(acc);
        PricebookEntry pbeProd1 = TestDataFactory_Test.createPriceBookEntryForTesting(prod1);
        PricebookEntry pbeProd2 = TestDataFactory_Test.createPriceBookEntryForTesting(prod2);
        
        OpportunityLineItem oli1 = new OpportunityLineItem(
        OpportunityId = opp.Id,
        Plots__c = 'Plot1',
        PricebookEntryId = pbeProd1.Id,
        Quantity = OPP_LINE1_QUANTITY,
        UnitPrice = 10,
        Quantity_per_hectare__c = 10,
        Date__c = System.today(),
        Plot_Size__c = 10,
        N__c = OPP_LINE1_N,
        P__c = OPP_LINE1_P,
        K__c = OPP_LINE1_K 
        );
        insert oli1;
        
        OpportunityLineItem oli2 = new OpportunityLineItem(
        PricebookEntryId = pbeProd2.Id,
        Plots__c = 'Plot1',
        OpportunityId = opp.Id,
        Quantity = 1,
        UnitPrice = 10,
        Quantity_per_hectare__c = 10,
        Date__c = System.today(),
        Plot_Size__c = 10,
        N__c = OPP_LINE2_N,
        P__c = OPP_LINE2_P,
        K__c = OPP_LINE2_K
        );
        insert oli2;


        OpportunityLineItem oli3 = new OpportunityLineItem(
        Plots__c = 'Plot2',
        PricebookEntryId = pbeProd1.Id,
        OpportunityId = opp.Id,
        Quantity = OPP_LINE3_QUANTITY,
        UnitPrice = 10,
        Quantity_per_hectare__c = 10,
        Date__c = System.today(),
        Plot_Size__c = 10,
        N__c = OPP_LINE2_N,
        P__c = OPP_LINE2_P,
        K__c = OPP_LINE2_K
        );
        insert oli3;
        
        
        
        
        
    }
    @isTest
    private static void getPlotsMap_Test(){
        
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name='Test Oppertunity' LIMIT 1];
        
        
        YearlyPlanEmailByPlotsController controller = new YearlyPlanEmailByPlotsController();
        controller.oppIdFromVFEmailTemplate = opp.id;
        
        
        Test.startTest();
        Test.stopTest();
        System.assertEquals(null, controller.getFatalExceptionMessage());
    }
    @isTest
    private static void getSumOfPlotsSizeMap_Test(){
        
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name='Test Oppertunity' LIMIT 1];
        
        YearlyPlanEmailByPlotsController controller = new YearlyPlanEmailByPlotsController();
        controller.oppIdFromVFEmailTemplate = opp.id;
        
        
        Test.startTest();
       controller.getSumOfPlotsSizeMap();
        Test.stopTest();
        System.assertEquals(null, controller.getFatalExceptionMessage());
    }
    @isTest
    private static void getOppLineGroupeResultsMap_Test(){
        
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name='Test Oppertunity' LIMIT 1];
        
        
        YearlyPlanEmailByPlotsController controller = new YearlyPlanEmailByPlotsController();
        controller.oppIdFromVFEmailTemplate = opp.id;
        
        
        Test.startTest();
        controller.getOppLineGroupeResultsMap();
        Test.stopTest();
        System.assertEquals(null, controller.getFatalExceptionMessage());
    }
    
    @isTest
    private static void getMonthe_Test(){
        
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name='Test Oppertunity' LIMIT 1];
        
        
        YearlyPlanEmailByPlotsController controller = new YearlyPlanEmailByPlotsController();
        controller.oppIdFromVFEmailTemplate = opp.id;
        
        
        Test.startTest();
        controller.getMonthes();
        Test.stopTest();
        System.assertEquals(null, controller.getFatalExceptionMessage());
    }
    
    @isTest
    private static void exceptionOnWrongOppId_Test(){
        
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name='Test Oppertunity' LIMIT 1];
        
        
        YearlyPlanEmailByPlotsController controller = new YearlyPlanEmailByPlotsController();
        controller.oppIdFromVFEmailTemplate = '123';

        Test.startTest();
        Test.stopTest();
        System.assertEquals('שגיאה בקבלת מידע, בדוק פרטי תכנית שנתית', controller.getFatalExceptionMessage());
    }


    @isTest
    private static void sumNPKAssersion_Test(){
        
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name='Test Oppertunity' LIMIT 1];
        
        
        YearlyPlanEmailByPlotsController controller = new YearlyPlanEmailByPlotsController();
        controller.oppIdFromVFEmailTemplate = opp.Id;
        controller.getPlotsMap();
        controller.getColumnTitle();
        controller.getAmountOfOppLineItems();


        Test.startTest(); 
        Test.stopTest();
        System.assertEquals(OPP_LINE1_N + OPP_LINE2_N, controller.getSumOfPlotsSizeMap().get('Plot1').get('SummedN'));
        System.assertEquals(OPP_LINE1_P + OPP_LINE2_P, controller.getSumOfPlotsSizeMap().get('Plot1').get('SummedP'));
        System.assertEquals(OPP_LINE1_K + OPP_LINE2_K, controller.getSumOfPlotsSizeMap().get('Plot1').get('SummedK'));
        
    }

    @isTest
    private static void sumQuantityByMonthAssersion_Test(){
        
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name='Test Oppertunity' LIMIT 1];
        
        
        YearlyPlanEmailByPlotsController controller = new YearlyPlanEmailByPlotsController();
        controller.oppIdFromVFEmailTemplate = opp.Id;


        Test.startTest(); 
        Test.stopTest();
        System.assertEquals( OPP_LINE1_QUANTITY + OPP_LINE3_QUANTITY, Decimal.valueOf(controller.getOppLineGroupeResultsMap().get('Product1').get('Sum')));
        
    }
}