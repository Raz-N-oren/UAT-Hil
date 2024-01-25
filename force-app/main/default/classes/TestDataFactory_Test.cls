@isTest
public with sharing class TestDataFactory_Test {
    // Creates and inserts Product_Staging__c records with properties defined by the calling test class
    public static List<Product_Staging__c> createProductStagingRecords(
        final Integer NUM_OF_PRODUCT_STAGING_TO_CREATE,
        final String STATUS_WAITING,
        final String SOURCE_SYSTEM,
        final String EXTENSION_EXID_SUFFIX,
        final String MASTERPROD_EXID_SUFFIX,
        final Integer SET_AMOUNT_STATUS_DIFF_THEN_WAITING,
        final String SAP_NUMBER
    ) {
        final String STATUS_PASS = 'Success';
        final String STATUS_FAIL = 'Error';
        final String STATUS_NEW = 'New';
        final Integer RATIO_N = 3;
        final Integer RATIO_P = 3;
        final Integer RATIO_K = 3;
        
        // create pro Staging accounts
        String status;
        List<Product_Staging__c> proStagingList = new List<Product_Staging__c>(); // holding product staging to insert later
        for (Integer i = 0; i < NUM_OF_PRODUCT_STAGING_TO_CREATE; i++) {
            if (i < SET_AMOUNT_STATUS_DIFF_THEN_WAITING) {
                status = STATUS_NEW;
            } else {
                status = STATUS_WAITING;
            }
            Product_Staging__c prodStage = new Product_Staging__c(
                Status__c = status,
                Product_Name__c = 'New name ' + i,
                N__c = RATIO_N,
                P__c = RATIO_P,
                K__c = RATIO_P,
                Source_System__c = SOURCE_SYSTEM,
                Sap_Number__c = SAP_NUMBER + i,
                Master_product__c = MASTERPROD_EXID_SUFFIX,
                Extension_1__c = EXTENSION_EXID_SUFFIX,
                Extension_2__c = EXTENSION_EXID_SUFFIX,
                Extension_3__c = EXTENSION_EXID_SUFFIX,
                Extension_4__c = EXTENSION_EXID_SUFFIX,
                Extension_5__c = EXTENSION_EXID_SUFFIX,
                Extension_6__c = EXTENSION_EXID_SUFFIX,
                Extension_7__c = EXTENSION_EXID_SUFFIX,
                Extension_8__c = EXTENSION_EXID_SUFFIX
            );
            proStagingList.add(prodStage);
        }
        insert proStagingList;
        return proStagingList;
    }
    
    // Creates and inserts Product2 records with properties defined by the calling test class
    public static List<Product2> createProduct2Records(
        final Integer NUM_OF_PRODUCT2_TO_CREATE,
        final String PROD2_PROD_EXID,
        final String PROD2_MASTER_EXID,
        final String PROD2_EXTENSION_EXID
    ) {
        List<Product2> prod2List = new List<Product2>();
        for (Integer i = 0; i < NUM_OF_PRODUCT2_TO_CREATE; i++) {
            Product2 prod2 = new Product2();
            prod2.External_Id__c = PROD2_PROD_EXID + i;
            prod2.Dingers_Good__c='Old name ' + i;
            prod2.Name = 'Old name ' + i; // 'Old name i' should be change to 'new name i' after product upserting
            prod2List.add(prod2);
        }
        insert prod2List;
        
        // Demo extension for having externalID in the DB to be matched by the ProductStagingTriggerHelper
        Product2 proDemoExtension = new Product2();
        proDemoExtension.External_Id__c = 'amf00000000demoextension';
        proDemoExtension.Name = 'Demo extension';
        insert proDemoExtension;
        
        // Demo MasterProduct for having externalID in the DB to be matched by the ProductStagingTriggerHelper
        Product2 prodDemoMasterProduct = new Product2();
        prodDemoMasterProduct.External_Id__c = 'amf00000000demomaster';
        prodDemoMasterProduct.Name = 'Demo masterProduct';
        insert prodDemoMasterProduct;
        
        return prod2List;
    }
    
    public static List<Account_Staging__c> createAccountStagingRecords(
        final Integer NUM_OF_ACC_STAGING_BULKS_CREATE,
        final String STATUS,
        final string SYSTEM_SOURCE
    ) {
        List<Account_Staging__c> accStageList = new List<Account_Staging__c>();
        
        for (Integer i = 0; i < NUM_OF_ACC_STAGING_BULKS_CREATE; i++) {
            Account_Staging__c actionTypeAccount = (createAccStageAccount(i, STATUS, SYSTEM_SOURCE));
            Account_Staging__c actionTypeSalesArea = (createAccStageSalesArea(i, STATUS, actionTypeAccount));
            Account_Staging__c actionTypePartnerFunction = (createPartnerFunction(
                i,
                STATUS,
                actionTypeAccount,
                actionTypeSalesArea
            ));
            // Contacts can be only from 'FER'
            Account_Staging__c actionTypeContactPartner;
            if (SYSTEM_SOURCE == 'FER') {
                actionTypeContactPartner = (createAccStageContactPartner(i, STATUS, actionTypeAccount));
            }
            
            accStageList.add(actionTypeAccount);
            accStageList.add(actionTypeSalesArea);
            accStageList.add(actionTypePartnerFunction);
            if (SYSTEM_SOURCE == 'FER') {
                accStageList.add(actionTypeContactPartner);
            }
        }
        return accStageList;
    }
    
    public static Account_Staging__c createAccStageAccount(Integer i, final String STATUS, final string SYSTEM_SOURCE) {
        final String ACC_STAGE = 'account';
        
        Account_Staging__c accStageAccount = new Account_Staging__c();
        accStageAccount.Action_Type__c = 'Account';
        accStageAccount.Account_Name__c = ACC_STAGE + i;
        accStageAccount.Account_Source__c = SYSTEM_SOURCE;
        accStageAccount.Business_Unit__c = ACC_STAGE + i;
        accStageAccount.Country__c = SYSTEM_SOURCE == 'FER' ? 'IL' : 'FR';
        accStageAccount.Division__c = 'Division01';
        accStageAccount.Distribution_Channel__c = 'Distribution_Channel02';
        accStageAccount.Fax__c = ACC_STAGE + i;
        accStageAccount.Industry__c = ACC_STAGE + i;
        accStageAccount.Phone__c = ACC_STAGE + i;
        accStageAccount.SAP_AccGr_text__c = SYSTEM_SOURCE == 'QAD' ? 'customer' : '';
        accStageAccount.SAP_Account_Group__c = SYSTEM_SOURCE == 'FER' ? ACC_STAGE + i : 'ZCEU';
        // accStageAccount.Sap_Number__c = 'sap' + i;
        accStageAccount.Sap_Number__c = String.valueOf(1000000 + Integer.valueof((Math.random() * 1000000)));
        accStageAccount.Status__c = STATUS;
        return accStageAccount;
    }
    
    public static Account_Staging__c createAccStageSalesArea( Integer i,final String STATUS, Account_Staging__c actionTypeAccount) {
        final String ACC_STAGE = 'salesArea';
        
        Account_Staging__c accStageSalesArea = new Account_Staging__c();
        accStageSalesArea.Action_Type__c = 'Sales Area';
        accStageSalesArea.Account_Name__c = ACC_STAGE + i;
        accStageSalesArea.Fax__c = ACC_STAGE + i;
        accStageSalesArea.Industry__c = ACC_STAGE + i;
        accStageSalesArea.Phone__c = ACC_STAGE + i;
        accStageSalesArea.SAP_Account_Group__c = ACC_STAGE + i;
        accStageSalesArea.Country__c = ACC_STAGE + i;
        accStageSalesArea.Sap_Number__c = actionTypeAccount.Sap_Number__c;
        accStageSalesArea.Account_Source__c = actionTypeAccount.Account_Source__c;
        accStageSalesArea.Status__c = STATUS;
        accStageSalesArea.Currency__c = 'EUR';
        accStageSalesArea.Business_Unit__c = 'FER7010';
        accStageSalesArea.Distribution_Channel__c = '02';
        accStageSalesArea.Division__c = 'CCPA';
        return accStageSalesArea;
    }
    
    public static Account_Staging__c createPartnerFunction( Integer i,final String STATUS,Account_Staging__c actionTypeAccount,Account_Staging__c actionTypeSalesArea) {
        final String ACC_STAGE = 'partnerFunction';
        
        Account_Staging__c accStagePartnerFunction = new Account_Staging__c();
        accStagePartnerFunction.Action_Type__c = 'Partner function';
        accStagePartnerFunction.Account_Name__c = ACC_STAGE + i;
        accStagePartnerFunction.Fax__c = ACC_STAGE + i;
        accStagePartnerFunction.Industry__c = ACC_STAGE + i;
        accStagePartnerFunction.Phone__c = ACC_STAGE + i;
        accStagePartnerFunction.SAP_Account_Group__c = ACC_STAGE + i;
        accStagePartnerFunction.Country__c = ACC_STAGE + i;
        accStagePartnerFunction.Sap_Number__c = actionTypeAccount.Sap_Number__c;
        accStagePartnerFunction.Sap_Number_2__c = actionTypeAccount.Sap_Number__c;
        accStagePartnerFunction.Status__c = STATUS;
        accStagePartnerFunction.Account_Source__c = actionTypeAccount.Account_Source__c;
        accStagePartnerFunction.Business_Unit__c = actionTypeSalesArea.Business_Unit__c;
        accStagePartnerFunction.Distribution_Channel__c = actionTypeSalesArea.Distribution_Channel__c;
        accStagePartnerFunction.Division__c = actionTypeSalesArea.Division__c;
        accStagePartnerFunction.Partnering_TYPE__c = 'SP';
        return accStagePartnerFunction;
    }
    
    public static Account_Staging__c createAccStageContactPartner(Integer i,final string STATUS,Account_Staging__c actionTypeAccount ) {
        final String ACC_STAGE = 'contactpartner';
        
        Account_Staging__c actionTypeContactPartner = new Account_Staging__c();
        actionTypeContactPartner.Action_Type__c = 'Contact Partner';
        actionTypeContactPartner.Status__c = STATUS;
        actionTypeContactPartner.Account_Source__c = actionTypeAccount.Account_Source__c;
        actionTypeContactPartner.Sap_Number__c = actionTypeAccount.Sap_Number__c;
        actionTypeContactPartner.CPmail__c = 'cp' + i + '@test.com';
        actionTypeContactPartner.Cplname__c = ACC_STAGE + i;
        actionTypeContactPartner.Cpfname__c = ACC_STAGE + i;
        actionTypeContactPartner.CpN__c = ACC_STAGE + i;
        return actionTypeContactPartner;
    }
    
    public static Plot__c createPlotForTesting(Account acc, Branch_growth__c branchGrowth) {
        Plot__c plot = new Plot__C();
        plot.Branch_growth__c = branchGrowth.id;
        plot.Name = 'Test Plot';
        plot.Plot_Size__c = 5;
        plot.Account__c =acc.Id;
        insert plot;
        return plot;
    }
    
    public static Plot_Tank_Junction__c createFertilizerHeadForTesting() {
        // 'Fertilizer Head' is the Label for Plot_Tank_Junction__c
        Plot_Tank_Junction__c fertilizerHead = new Plot_Tank_Junction__c(Name = 'Test Fertilizer Head');
        insert fertilizerHead;
        return fertilizerHead;
    }
    
    public static Branch_growth__c createBranchGrowthForTesting(Account acc) {
        Branch_growth__c branchGrowth = new Branch_growth__c();
        branchGrowth.Account__c = acc.Id;
        branchGrowth.Name = 'testBranchGrowth';
        insert branchGrowth;
        return branchGrowth;
    }
    
    public static list<Account> createAccountForTesting(final Integer NUM_OF_ACCOUNTS_TO_CREATE) {
        List<String> srcSys = AccountStagingTriggerHelper.sourceSys;
        List<Account> accList = new List<Account>();
        
        for (Integer i = 0; i < NUM_OF_ACCOUNTS_TO_CREATE; i++) {
            Account acc = new Account();
            acc.Name = NUM_OF_ACCOUNTS_TO_CREATE == 1 ? 'Test Account' : 'Test Account ' + i;
            acc.Classification__c = 'גדול';
            acc.Sap_Number__c = String.valueOf(Integer.valueof((Math.random() * 1000000)));
            acc.AccountSource = srcSys[Math.mod(i,srcSys.size())];
            acc.External_Id__c = acc.AccountSource == 'FER' ? acc.Sap_Number__c : null;
            acc.Amfert_SAP_number__c = acc.AccountSource == 'AMF' ? acc.Sap_Number__c : null;
            acc.IBP_SAP_number__c = acc.AccountSource == 'IBP' ? acc.Sap_Number__c : null;
            acc.QAD1_sap_C__c = acc.AccountSource == 'QAD' ? acc.Sap_Number__c : null;
            acc.BRAZIL_SAP_NUMBER__c = acc.AccountSource == 'BRA' ? acc.Sap_Number__c : null;
            acc.US_SAP_NUMBER__c = acc.AccountSource == 'PLP' ? acc.Sap_Number__c : null;
            acc.India_Thali_Number__c = acc.AccountSource == 'E0228' ? acc.Sap_Number__c : null;
            acc.lAND__c = acc.AccountSource == 'E0035' ? acc.Sap_Number__c : null;
            acc.TRK_SAP__c = acc.AccountSource == 'TRK' ? acc.Sap_Number__c : null;
            acc.Fun_erp_number__c = acc.AccountSource == 'FNT' ? acc.Sap_Number__c : null;
            accList.add(acc);
        }
        insert accList;
        return accList;
    }
    
    public static list<Account> createAccountCMSForTesting(final Integer NUM_OF_ACCOUNTS_TO_CREATE) {
        List<String> srcSys = AccountStagingTriggerHelper.sourceSys;
        List<Account> accList = new List<Account>();
        
        for (Integer i = 0; i < NUM_OF_ACCOUNTS_TO_CREATE; i++) {
            Account acc = new Account();
            acc.Name = NUM_OF_ACCOUNTS_TO_CREATE == 1 ? 'Test Account' : 'Test Account ' + i;
            acc.Classification__c = 'גדול';
            acc.Sap_Number__c = String.valueOf(Integer.valueof((Math.random() * 1000000)));
            acc.AccountSource = srcSys[Math.mod(i,srcSys.size())];
            acc.External_Id__c = acc.AccountSource == 'FER' ? acc.Sap_Number__c : null;
            acc.Amfert_SAP_number__c = acc.AccountSource == 'AMF' ? acc.Sap_Number__c : null;
            acc.IBP_SAP_number__c = acc.AccountSource == 'IBP' ? acc.Sap_Number__c : null;
            acc.QAD1_sap_C__c = acc.AccountSource == 'QAD' ? acc.Sap_Number__c : null;
            acc.BRAZIL_SAP_NUMBER__c = acc.AccountSource == 'BRA' ? acc.Sap_Number__c : null;
            acc.US_SAP_NUMBER__c = acc.AccountSource == 'PLP' ? acc.Sap_Number__c : null;
            acc.India_Thali_Number__c = acc.AccountSource == 'E0228' ? acc.Sap_Number__c : null;
            acc.lAND__c = acc.AccountSource == 'E0035' ? acc.Sap_Number__c : null;
            acc.TRK_SAP__c = acc.AccountSource == 'TRK' ? acc.Sap_Number__c : null;
            acc.Fun_erp_number__c = acc.AccountSource == 'FNT' ? acc.Sap_Number__c : null;
            acc.Customer_credit_file_in_CM__c='Customer_credit_file_in_CM__c'+i;
            accList.add(acc);
        }
        insert accList;
        return accList;
    }
    
    public static New_Product_request__c createNewProduct(){
        New_Product_request__c NPR= new New_Product_request__c(
            Process_Type__c='Sap Update',
            Description__c='bla bla test', 
            Status__c='Open',
            N__c=10
        );
        insert NPR;
        return NPR;
    }
    
    public static List<Product2> createProductForTesting(final Integer NUM_OF_PRODUCTS_TO_CREATE) {
        List<Product2> products = new List<Product2>();
        for (Integer i = 0; i < NUM_OF_PRODUCTS_TO_CREATE; i++) {
            Product2 product = new Product2(
                Name = 'Product test' + i,
                ProductCode = 'Product code Test' + i,
                Family = 'DSH_03',
                K__c = 10 + i,
                N__c = 9 + i,
                P__c = 8 + i,
                B__c = 7 + i,
                Ca__c = 6 + i,
                CL__c = 5 + i,
                CO__c = 4 + i,
                Fe__c = 2 + i,
                IS__c = 1 + i,
                Mg__c = 0 + i,
                Mn__c = 11 + i,
                PH__c = 12 + i,
                ZN__c = 13 + i,
                specific_gravity__c = 1.25,
                Sap_Number__c='12798h983'
            );
            products.add(product);
        }
        return products;
    }
    
    public static Discount_Matrix__c createDisMatForTesting() {
        Discount_Matrix__c DisMat = new Discount_Matrix__c(Name = 'Test Matrix', Status__c = 'תקף');
        insert DisMat;
        return DisMat;
    }
    
    public static List<Discount_matrix_Line__c> createDisMatLineForTesting(Id matrixId,final Integer NUM_OF_DIML_TO_CREATE) {
        List<Discount_matrix_Line__c> DisMLs = new List<Discount_matrix_Line__c>();
        for (Integer i = 0; i < NUM_OF_DIML_TO_CREATE; i++) {
            Discount_matrix_Line__c DisML = new Discount_matrix_Line__c(
                Customer_Size__c = 'גדול',
                Product_Family__c = 'A',
                Discount_Matrix__c = matrixId,
                Target_Discount__c = 15 + i,
                Max_Discount__c = 20 + i
            );
            DisMLs.add(DisML);
        }
        insert DisMLs;
        return DisMLs;
    }
    
    public static Discount__c createNewDiscount(Id AccountId,Id productId){
        Discount__c newDiscount = new Discount__c(
            Status__c='לא תקף', 
            Display_Filter_2__c='מוצר', 
            Display_Filter_1__c='לקוח', 
            Account__c=AccountId, 
            Product__c=productId, 
            Requested_Discount__c=35, 
            End_Date__c= system.today().addYears(1), 
            Start_Date__c=system.today().addDays(-3), 
            Max_Discount__c=40, 
            Target_Discount__c=20
        );
        return newDiscount;
    }
    
    public static Product_hierarchy__c createSubProducthierarchy(){
        Product_hierarchy__c SubRec = new Product_hierarchy__c(
            Group__c='02110030001',
            Type__c='Sub Master Product',
            Division__c='0211',
            Family__c='0211003',
            External_ID__c='021100300010001',
            Name='חומצה למצברים'
        );
        insert SubRec;
        return SubRec;
    }
    
    public static Product_hierarchy__c createMasterProducthierarchy(){
        Product_hierarchy__c MasterRec = new Product_hierarchy__c(
            Group__c='02110030001',
            Type__c='Master Product',
            Division__c='0211',
            Family__c='0211003',
            External_ID__c='02110030001',
            Name='חומצה גופרתית'
        );
        insert MasterRec;
        return MasterRec;
    }
    
    public static IL_Price_Book__c createIlPriceBookForTesting(Id prodId) {
        
        IL_Price_Book__c ipb = new IL_Price_Book__c(
            k__c = 0,
            N__c = 1,
            p__c = 3,
            B__c = 4,
            Ca__c = 5,
            CL__c = 6,
            Co__c = 7,
            Fe__c = 9,
            IS__c = 10,
            Mg__c = 11,
            Mn__c = 12,
            Ph__c = 13,
            Zn__c = 14,
            Fixed_Price__c = 150,
            Start_Date__c = system.today().addDays(-2),
            End_Date__c = system.today().addyears(1),
            Product_Family__c = 'DSH_02',
            Product_Service__c = prodId,
            Status__c = 'תקף',
            Unit_Of_Meager__c = 'TO'
        );
        insert ipb;
        return ipb;
    }
    public static IL_Price_Book__c createIlChemicalPriceBookForTesting(Id prodId,Id AccountId) {
        
        IL_Price_Book__c ipb = new IL_Price_Book__c(
            Account__c=AccountId,
            k__c = 0,
            N__c = 1,
            p__c = 3,
            B__c = 4,
            Ca__c = 5,
            CL__c = 6,
            Co__c = 7,
            Fe__c = 9,
            IS__c = 10,
            Mg__c = 11,
            Mn__c = 12,
            Ph__c = 13,
            Zn__c = 14,
            Fixed_Price__c = 150,
            Start_Date__c = system.today().addDays(-2),
            End_Date__c = system.today().addyears(1),
            Product_Family__c = 'DSH_02',
            Product_Service__c = prodId,
            Status__c = 'תקף',
            Unit_Of_Meager__c = 'TO',
            ChemicalTransportPrice__c=500
        );
        insert ipb;
        return ipb;
    }
    
    public static IL_Price_Book__c createIlPriceBookOpportunityForTesting(Id prodId,Id Opp) {
        IL_Price_Book__c ipb = new IL_Price_Book__c(
            k__c = 0,
            N__c = 1,
            p__c = 3,
            B__c = 4,
            Ca__c = 5,
            CL__c = 6,
            Co__c = 7,
            Fe__c = 9,
            IS__c = 10,
            Mg__c = 11,
            Mn__c = 12,
            Ph__c = 13,
            Zn__c = 14,
            Fixed_Price__c = 150,
            Start_Date__c = Date.newInstance(2021, 4, 4),
            End_Date__c = Date.newInstance(2021, 10, 7),
            Product_Family__c = 'DSH_02',
            Product_Service__c = prodId,
            Opportunity__c=Opp,
            Status__c = 'תקף',
            Unit_Of_Meager__c = 'TO'
        );
        insert ipb;
        return ipb;
    }
    
    public static Growth__c createGrowthForTesting(Plot__c plot) {
        Growth__c growth = new Growth__c();
        growth.Plot__c = plot.Id;
        insert growth;
        return growth;
    }
    
    public static Product_Group_Category__c createProdGroupCategoryForTesting(String prodFamily, String prodFamilyCat) {
        Product_Group_Category__c prodGrCat = new Product_Group_Category__c(
            Product_Family_Category__c = prodFamily,
            Product_Family__c = prodFamilyCat
        );
        insert prodGrCat;
        return prodGrCat;
    }
    
    public static Opportunity createOpportunityForTesting(Account acc) {
        Opportunity opp = new Opportunity(
            AccountId = acc.Id,
            Name = 'Test Oppertunity',
            StageName = 'Prospecting',
            CloseDate = Date.today()
            
        );
        insert opp;
        return opp;
    }
    
    public static OpportunityLineItem createOpportunityLineItemForTesting( Account acc,Opportunity opp, Product2 p2,PricebookEntry pbe) {
        OpportunityLineItem oli = new OpportunityLineItem(
            PriceBookEntryId = pbe?.Id, // Using safe operator as pbe is mandatory for this test method
            OpportunityId = opp.Id,
            Product2Id = p2?.Id,
            Quantity = 1,
            Quantity_per_hectare__c = 2,
            Unit_of_measure__c = 'TO',
            unitPrice = 797, // Actually should be  quantity * pbe.UnitPrice
            Date__c = Date.newinstance(Date.today().year(), Date.today().month(), Date.today().day())
        );
        return oli;
    }
    
    public static PricebookEntry createPriceBookEntryForTesting(Product2 p2) {
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = p2.Id,
            UnitPrice = 99,
            isActive = true
        );
        insert pbe;
        return pbe;
    }
    
    public static Lab_Test__c createLabTestForTesting(ID accId) {
        Lab_Test__c labTest = new Lab_Test__c(
            Account__c = accId,
            // Name = 'Test Lab Test',
            // ampling_date__c = Date.newInstance(2020, 2, 17),
            Status__c = 'טיוטה',
            Type__c = '4'
        );
        insert labTest;
        return labTest;
    }
    
    public static Sample_data__c createSampleDataForTesting(ID accId, ID labTestId) {
        Sample_data__c sd = new Sample_data__c(
            Account__c = accId,
            Lab_Test__c = labTestId,
            // Sampling_date__c = Date.newInstance(2020, 2, 17),
            Status__c = 'פתוח',
            Type__c = '4',
            SP__c = true,
            E_C__c = true
        );
        insert sd;
        return sd;
    }
    
    public static void createStaticObjectsRecordsForTesting() {
        /////////////////////////////////////////////////////////////////////
        ///// -- Populate Lab_Tests_List__c Object with few options -- //////
        /////////////////////////////////////////////////////////////////////
        
        List<Lab_Tests_List__c> ltls = new List<Lab_Tests_List__c>();
        
        Lab_Tests_List__c sp = new Lab_Tests_List__c(
            Test_Code__c = '1',
            Name = '(SP) אחוז רוויה',
            MitMidEnNmae__c = 'SP',
            MitMidEbName__c = 'אחוז רוויה',
            MitGroupID__c = 'כללי',
            MitUnitID__c = '%',
            Type__c = '4', //'(6)עלים או פרי צמחים(3);קרקעות(4);תמיסת מים(2);כימיקלים תעשייתיים'
            Check_Box_Api_Name__c = 'SP__c'
        );
        
        Lab_Tests_List__c ec = new Lab_Tests_List__c(
            Test_Code__c = '2',
            Name = '(E.C) מוליכות חשמלית',
            MitMidEnNmae__c = 'E.C',
            MitMidEbName__c = 'מוליכות חשמלית',
            MitGroupID__c = 'כללי',
            MitUnitID__c = 'dsi',
            Type__c = '4;2', //'(6)עלים או פרי צמחים(3);קרקעות(4);תמיסת מים(2);כימיקלים תעשייתיים'
            Check_Box_Api_Name__c = 'E_C__c'
        );
        
        Lab_Tests_List__c ph = new Lab_Tests_List__c(
            Test_Code__c = '3',
            Name = '(pH) תגובת הקרקע',
            MitMidEnNmae__c = 'pH',
            MitMidEbName__c = 'תגובת הקרקע',
            MitGroupID__c = 'כללי',
            MitUnitID__c = 'חומציות',
            Type__c = '4', //'(6)עלים או פרי צמחים(3);קרקעות(4);תמיסת מים(2);כימיקלים תעשייתיים'
            Check_Box_Api_Name__c = 'pH__c'
        );
        
        Lab_Tests_List__c ph2 = new Lab_Tests_List__c(
            Test_Code__c = '6',
            Name = '(pH) תגובת התמיסה',
            MitMidEnNmae__c = 'pH',
            MitMidEbName__c = 'תגובת התמיסה',
            MitGroupID__c = 'כללי',
            MitUnitID__c = 'חומציות',
            Type__c = '2;6', //'(6)עלים או פרי צמחים(3);קרקעות(4);תמיסת מים(2);כימיקלים תעשייתיים'
            Check_Box_Api_Name__c = 'pH2__c'
        );
        
        Lab_Tests_List__c spgr = new Lab_Tests_List__c(
            Test_Code__c = '7',
            Name = '(Spgr) משקל סגולי',
            MitMidEnNmae__c = 'Spgr',
            MitMidEbName__c = 'משקל סגולי',
            MitGroupID__c = 'כללי',
            MitUnitID__c = 'ג\'/סמ"ק',
            Type__c = '6', //'(6)עלים או פרי צמחים(3);קרקעות(4);תמיסת מים(2);כימיקלים תעשייתיים'
            Check_Box_Api_Name__c = 'Spgr__c'
        );
        
        ltls.add(sp);
        ltls.add(ec);
        ltls.add(ph);
        ltls.add(ph2);
        ltls.add(spgr);
        
        ltls.add(
            new Lab_Tests_List__c(
                Test_Code__c = '15',
                Name = '(Cl) כלור',
                MitMidEnNmae__c = 'Cl',
                MitMidEbName__c = 'כלור',
                MitGroupID__c = 'קטיונים',
                MitUnitID__c = '%',
                Type__c = '6', //'(6)עלים או פרי צמחים(3);קרקעות(4);תמיסת מים(2);כימיקלים תעשייתיים'
                Check_Box_Api_Name__c = 'Cl__c'
            )
        );
        
        ltls.add(
            new Lab_Tests_List__c(
                Test_Code__c = '16',
                Name = '(K2O) תחמוצת האשלגן',
                MitMidEnNmae__c = 'K2O',
                MitMidEbName__c = 'תחמוצת האשלגן',
                MitGroupID__c = 'אשלגן',
                MitUnitID__c = '%',
                Type__c = '6', //'(6)עלים או פרי צמחים(3);קרקעות(4);תמיסת מים(2);כימיקלים תעשייתיים'
                Check_Box_Api_Name__c = 'K2O__c'
            )
        );
        
        ltls.add(
            new Lab_Tests_List__c(
                Test_Code__c = '18',
                Name = 'ברזל (Fe)',
                MitMidEnNmae__c = 'Fe',
                MitMidEbName__c = 'ברזל',
                MitGroupID__c = 'מיקרואלמנטים',
                MitUnitID__c = 'ppm',
                Type__c = '2;3;4;6', //'(6)עלים או פרי צמחים(3);קרקעות(4);תמיסת מים(2);כימיקלים תעשייתיים'
                Check_Box_Api_Name__c = 'Fe__c'
            )
        );
        
        ltls.add(
            new Lab_Tests_List__c(
                Test_Code__c = '25',
                Name = 'כלור (Cl)',
                MitMidEnNmae__c = 'FCl',
                MitMidEbName__c = 'כלור',
                MitGroupID__c = 'אניונים',
                MitUnitID__c = 'mg/l',
                Type__c = '4', //'(6)עלים או פרי צמחים(3);קרקעות(4);תמיסת מים(2);כימיקלים תעשייתיים'
                Check_Box_Api_Name__c = 'Cl__c'
            )
        );
        ltls.add(
            new Lab_Tests_List__c(
                Test_Code__c = '38',
                Name = 'כלור (Cl)',
                MitMidEnNmae__c = 'FCl',
                MitMidEbName__c = 'כלור',
                MitGroupID__c = 'אניונים',
                MitUnitID__c = 'mg/l',
                Type__c = '3', //'(6)עלים או פרי צמחים(3);קרקעות(4);תמיסת מים(2);כימיקלים תעשייתיים'
                Check_Box_Api_Name__c = 'Cl__c'
            )
        );
        
        ltls.add(
            new Lab_Tests_List__c(
                Test_Code__c = '8',
                Name = 'חנקן חנקתי (N-NO3)',
                MitMidEnNmae__c = 'N-NO3',
                MitMidEbName__c = 'חנקן חנקתי',
                MitGroupID__c = 'חנקן',
                MitUnitID__c = '%',
                Check_Box_Api_Name__c = 'N_NO3__c'
            )
        );
        
        insert ltls;
        
        ///////////////////////////////////////////////////////////////////////////////
        ///// -- Populate Lab_test_Reference_table__c Object with few options -- //////
        ///////////////////////////////////////////////////////////////////////////////
        
        List<Lab_test_Reference_table__c> ltrts = new List<Lab_test_Reference_table__c>();
        
        ltrts.add(
            new Lab_test_Reference_table__c(
                desired_value__c = 15.00,
                Maximum_value__c = 20.00,
                Minimum_value__c = 10.00,
                Component_tested__c = sp.id,
                Type__c = '4'
            )
        );
        
        ltrts.add(
            new Lab_test_Reference_table__c(
                desired_value__c = 25.00,
                Maximum_value__c = 30.00,
                Minimum_value__c = 20.00,
                Component_tested__c = ec.id,
                Type__c = '4'
            )
        );
        
        ltrts.add(
            new Lab_test_Reference_table__c(
                desired_value__c = 17.00,
                Maximum_value__c = 22.00,
                Minimum_value__c = 12.00,
                Component_tested__c = ec.id,
                Type__c = '2'
            )
        );
        
        ltrts.add(
            new Lab_test_Reference_table__c(
                desired_value__c = 60.00,
                Maximum_value__c = 70.00,
                Minimum_value__c = 50.00,
                Component_tested__c = ph.id,
                Type__c = '4'
            )
        );
        
        ltrts.add(
            new Lab_test_Reference_table__c(
                desired_value__c = 25.00,
                Maximum_value__c = 40.00,
                Minimum_value__c = 10.00,
                Component_tested__c = ph2.id,
                Type__c = '2'
            )
        );
        
        ltrts.add(
            new Lab_test_Reference_table__c(
                desired_value__c = 5.00,
                Maximum_value__c = 9.00,
                Minimum_value__c = 1.00,
                Component_tested__c = ph2.id,
                Type__c = '6'
            )
        );
        
        ltrts.add(
            new Lab_test_Reference_table__c(
                desired_value__c = 63.00,
                Maximum_value__c = 66.00,
                Minimum_value__c = 60.00,
                Component_tested__c = spgr.id,
                Type__c = '6'
            )
        );
        
        insert ltrts;
    }
    
    public static List<Sales_Information__c> createAndInsertSalesInformationWithRelationsForTesting(final Integer REQ_AMOUNT ) {
        // Create create sales_Information records and the related Accounts & Products
        List<Account> accs = createAccountForTesting(REQ_AMOUNT * 2);
        List<Product2> products = createProductForTesting(REQ_AMOUNT);
        List<Sales_Information__c> salesInfos = new List<Sales_Information__c>();
        
        for (Integer i = 0; i < REQ_AMOUNT; i++) {
            Sales_Information__c salesInfo = new Sales_Information__c();
            products[i].Source_System__c = salesInfo.Source_System__c = accs[i].AccountSource;
            salesInfo.Product_SAP_Nmuber__c = products[i].Sap_Number__c = accs[i].Sap_Number__c;
            products[i].External_Id__c = products[i].Source_System__c + products[i].Sap_Number__c;
            salesInfo.Ship_To_SAP_Number__c = accs[i].Sap_Number__c;
            salesInfo.Sold_To_Sap_Number__c = accs[i + REQ_AMOUNT].Sap_Number__c;
            salesInfos.add(salesInfo);
        }
        insert products;
        return salesInfos;
    }
    
    public static OpportunityLineItem createOpportunityLineItemWithAllDependenciesForTesting() {
        // Create Account (alredy inserted in data factory)
        Account acc = createAccountForTesting(1)[0];
        
        // Creeate Opportunity (alredy inserted in data factory)
        Opportunity opp = createOpportunityForTesting(acc);
        
        //Create Product (not inserted in data factory)
        Product2 prod = createProductForTesting(1)[0];
        insert prod;
        
        // Create Price Book Entry (alredy inserted in data factory)
        PricebookEntry pbe = createPriceBookEntryForTesting(prod);
        
        // Create IL_Price_Book
        IL_Price_Book__c ilpb = createIlPriceBookForTesting(prod.id);
        
        // Create Opportunity Line Item (not inserted in data factory)
        OpportunityLineItem oli = createOpportunityLineItemForTesting(acc, opp, prod, pbe);
        oli.Quantity = 5;
        
        return oli;
    }
    
    // Create Contacts related to account without inserting
    public static List<Contact> createContactsForTesting(Id accId, Integer amount){
        List<Contact> cons = new List<Contact>();
        for(Integer i = 0 ; i < amount ; i++) {
            cons.add(new Contact(FirstName = 'First N' + i, LastName = 'Last N' + i, AccountId = accId,OperationalContact__c=true));
        }
        return cons;
    }
    
    // Create Contacts related to account with inserting
    public static List<Contact> createAndInsertContactsForTesting(Id accId, Integer amount){
        List<Contact> cons = createContactsForTesting(accId, amount);
        insert cons;
        return cons;
    }
    
    // Create Account and related contacts
    public static Account createAccountAndContactsForTesting(final Integer numOfContacts){
        Account acc = createAccountForTesting(1)[0];
        createAndInsertContactsForTesting(acc.Id, numOfContacts);
        return acc;
    }
    
    // Create Account Staging records with acction type of 'CM', related to the accounts received 
    public static List<Account_Staging__c> createAccountStagingForCMTesting(List<Account> accs){
        List<Account_Staging__c> accStgRecs = new List<Account_Staging__c>();
        for(Integer i = 0 ; i < accs.size() ; i++){
            Account_Staging__c accStg = createAccStageCM(i, 'Waiting', accs[i].AccountSource, accs[i].Sap_Number__c);
            accStgRecs.add(accStg);
        }
        return accStgRecs;
    }
    
    // Create Account Staging records with acction type of 'CM', related to the accounts received 
    public static List<Account_Staging__c> createAccountStagingForCMSTesting(List<Account> accs){
        List<Account_Staging__c> accStgRecs = new List<Account_Staging__c>();
        
        for(Integer i = 0 ; i < accs.size() ; i++){
            Account_Staging__c accStg = createAccStageCMS(i, 'Waiting', accs[i].AccountSource, accs[i].Sap_Number__c,accs[i].Id);
            accStgRecs.add(accStg);
            
            
        }
        INSERT accStgRecs;
        createExistingCMSrecords(accStgRecs);
        return accStgRecs;
    }
    
    
    public static Account_Staging__c createAccStageCM(Integer i, final string STATUS, String accSource, String sapNum) {
        // System.debug('In accStg creation - sapNum: ' + sapNum);
        Account_Staging__c accStg = new Account_Staging__c();
        accStg.Action_Type__c = 'CM';
        accStg.Status__c = STATUS;
        accStg.Account_Source__c = accSource != null ? accSource : 'FER';
        accStg.Sap_Number__c = // If exists use it, if not create random sap num
            sapNum != null ? sapNum : String.valueOf(1000000 + Integer.valueof((Math.random() * 1000000)));
        accStg.Customer_credit_file_in_CM__c = 'Customer credit file in CM ' + i;
        accStg.SABNR__c = '0000';
        accStg.KLIMK__c = 1.1 + i;
        accStg.OBLIG__c = 2.2 + i;
        accStg.RISKCL__c = 'RISKCL' + i;
        accStg.OPUFAEL__c = 3.3 + i;
        accStg.ATLBRTG__c = 'ATLBRTG ' + i;
        accStg.VIPCUS__c = 'VIPCUS ' + i;
        accStg.Currency__c = 'USD';
        return accStg;
    }
    
    public static Account_Staging__c createAccStageCMS(Integer i, final string STATUS, String accSource, String sapNum,string accountId) {
        // System.debug('In accStg creation - sapNum: ' + sapNum);
        Account_Staging__c accStg = new Account_Staging__c();
        accstg.Account__c=accountId;
        accStg.Action_Type__c = 'CM';
        accStg.Status__c = STATUS;
        accStg.Account_Source__c = accSource != null ? accSource : 'FER';
        accStg.Sap_Number__c = // If exists use it, if not create random sap num
            sapNum != null ? sapNum : String.valueOf(1000000 + Integer.valueof((Math.random() * 1000000)));
        accStg.Customer_credit_file_in_CM__c ='Customer_credit_file_in_CM__c'+i;
        accStg.SABNR__c = '000'+i;
        accStg.KLIMK__c = 1.1 + i;
        accStg.OBLIG__c = 2.2 + i;
        accStg.RISKCL__c = 'RISKCL' + i;
        accStg.OPUFAEL__c = 3.3 + i;
        accStg.ATLBRTG__c = 'ATLBRTG ' + i;
        accStg.VIPCUS__c = 'VIPCUS ' + i;
        accStg.Currency__c = 'USD';
        return accStg;
    }
    
    public static void createExistingCMSrecords( List<Account_Staging__c> testData){
        List<CraditSegment__c> accStgRecs = new List<CraditSegment__c>();
        for(Integer i = 0 ; i < testData.size() ; i++){
            if(i<20){
                CraditSegment__c rec= new CraditSegment__c(
                    Account__c          = testData[i].Account__c,
                    ATLBRTG__c          = testData[i].ATLBRTG__c,
                    Clerk_In_Charge__c  = testData[i].Clerk_In_Charge__c,
                    KLIMK__c            = testData[i].KLIMK__c,
                    Sgmnt_Txt__c        = testData[i].Sgmnt_Txt__c,
                    VIPCUS__c           = testData[i].VIPCUS__c,
                    RISKCL__c           = testData[i].RISKCL__c,
                    OPUFAEL__c          = testData[i].OPUFAEL__c,
                    OBLIG__c            = testData[i].OBLIG__c,
                    AccountStagingId__c = testData[i].Id,
                    SegmentCreditId__c  = testData[i].Account__c+testData[i].SABNR__c,
                    
                    OPUFAEL14__c		= testData[i].OPUFAEL14__c,
                    OPUFAEL29__c		= testData[i].OPUFAEL29__c,
                    OPUFAEL30__c		= testData[i].OPUFAEL30__c
                );
                system.debug(loggingLevel.ERROR, 'account staging:'+rec);
                accStgRecs.add(rec);
            }
        }
        insert accStgRecs;
    }
    
    // Create Account Staging records with acction type of 'CM', not related to any account 
    public static List<Account_Staging__c> createAccStgRecsWithoutAccounts(Integer numOfRecs){
        List<Account_Staging__c> accStgRecs = new List<Account_Staging__c>();
        for(Integer i = 0 ; i < numOfRecs ; i++){
            Account_Staging__c accStg = createAccStageCM(i, 'Waiting', null, null);
            accStgRecs.add(accStg);
        }
        return accStgRecs;
    } 
    
    public static order createOrder(){
        // Create Account (alredy inserted in data factory)
        List<Account> newAcc=createAccountForTesting(2);
        Account acc = newAcc[0];
        Account payingCust = newAcc[1];

   
        
        //Create Order
        order newOrder = new order(
            AccountId =acc.Id,
            EffectiveDate=system.today(),
            IntermediaryWarehouse__c=null,
            LabTestId__c=null,
            NonFreightCharge__c=false,
            Paying_Customer__c=payingCust.Id,
            Pricebook2Id=Test.getStandardPricebookId(),
            PrivateTransport__c=false,
            RequestedSupplyDate__c=system.today().addDays(2),
            Status='10',
            TransactionType__c='30'
            
        );
        insert newOrder;
        return newOrder;
    }
      public static order createChemicalOrder(){
          // Create Account (alredy inserted in data factory)
          List<Account> newAcc=createFlexiableAccountForTesting(3,'נוקסיקליר');
          Account acc = newAcc[0];
          Account payingCust = newAcc[1];
          
          
        
        //Create Order
        order newOrder = new order(
            AccountId =acc.Id,
            EffectiveDate=system.today(),
            IntermediaryWarehouse__c=newAcc[2].Id,
            LabTestId__c=null,
            NonFreightCharge__c=false,
            Paying_Customer__c=payingCust.Id,
            Pricebook2Id=Test.getStandardPricebookId(),
            PrivateTransport__c=false,
            RequestedSupplyDate__c=system.today().addDays(2),
            Status='10',
            TransactionType__c='30',
            AgentReceivesCommission__c= newAcc[2].Id
            
        );
        return newOrder;
    }
    
    public static LoadingPoint__c createLoadingPoint(string TypeLP){
        LoadingPoint__c newRec = new LoadingPoint__c(
            Name='חיפה כימיקלים דרום'+TypeLP,
            LoadingPointName__c='חיפה כימיקלים דרום',
            LoadingPointSapId__c='994357',
            LoadingPointType__c=TypeLP,
            Supplier_Sap_Id__c='2068'
        );
        insert newRec;
        return newRec;
    }
    
     public static Tank__c createDischargeLocation(Account acc){
        Tank__c newRec = new Tank__c(
            Name='נק פריקה בדיקה',
            Account__c	=acc.Id,
            Driver_Note__c ='this is a test from tanks',
            Settlement__c=createSettelment().Id,//create
            TaxiDelivery__c	=false
        );
        insert newRec;
        return newRec;
    }
       public static Tank__c createDischargeLocationGoogleInterface(Account acc){
        Tank__c newRec = new Tank__c(
            Name='נק פריקה בדיקה',
            Account__c	=acc.Id,
            Driver_Note__c ='this is a test from tanks',
            Settlement__c=createSettelment().Id,//create
            TaxiDelivery__c	=false
        );
        insert newRec;
        return newRec;
    }
    
    public static Setelment__c createSettelment(){
        Setelment__c newRec = new Setelment__c(
            Name='פרי גן',
            Form_of_settlement__c='3',
            Geographic_Area__c='10',
            SETTLEMENT_Address__c='ד.נ. הנגב',
            Trucking_area__c='91',
            General_coordinate__Latitude__s	=31.222015,
            General_coordinate__Longitude__s=34.355936
        );
        insert newRec;
        return newRec;
    }
    
    public static Product2 createExtentionInfo(){        
        //Create Product (not inserted in data factory)
        Product2 prod = createProductForTesting(1)[0];
        insert prod;
        
        // Create Price Book Entry (alredy inserted in data factory)
        PricebookEntry pbe = createPriceBookEntryForTesting(prod);
        
        // Create IL_Price_Book
        IL_Price_Book__c ilpb = createIlPriceBookForTesting(prod.id);
        
        return prod;
    }
    
    public static OrderItem createOrderItem(Order recOrder,Id ProducthierarchyId,Id LoadingPointId){
        Account acc = [SELECT Id FROM Account WHERE Id=:recOrder.AccountId];
        
        List<contact> con= createAndInsertContactsForTesting(acc.Id,2);
        // Creeate Opportunity (alredy inserted in data factory)
        Opportunity opp = createOpportunityForTesting(acc);
        
        //Create Product (not inserted in data factory)
        Product2 prod = createProductForTesting(1)[0];
        prod.Product_hierarchy__c=ProducthierarchyId;
        prod.External_Id__c='66'+string.valueOf(opp.Id).right(3)+ prod.External_Id__c;
        prod.Sap_Number__c=prod.External_Id__c;
        insert prod;
        
        // Create Price Book Entry (alredy inserted in data factory)
        PricebookEntry pbe = createPriceBookEntryForTesting(prod);
        
        // Create IL_Price_Book
        IL_Price_Book__c ilpb = createIlPriceBookForTesting(prod.id);
        ilpb.ChemicalTransportPrice__c=500;
        ilpb.Unit_Of_Meager__c='TO';
        ilpb.Account__C=acc.Id;
        ilpb.FillingFees__c= 250;
        update ilpb;
        
        orderItem OI =new orderItem(
            orderId=recOrder.Id,
            DischargeLocation__c=createDischargeLocation(acc).Id,//create
            LoadingPoint__c=LoadingPointId!=null?LoadingPointId:createLoadingPoint('ספק').Id,//create
            PricebookEntryId=pbe.Id,
            Price_from_customer_order__c=null,
            Product2Id=prod.Id,
            Quantity=8,
            Status__c='20',
            triggerProcessor__c=false,
            UnitOfMeasure__c='TO',
            UnitPrice=0,
            Extension_1__c=createExtentionInfo().Id,
            Extension_Quantity_1__c=1,
            Extension_Unit_1__c='TO',
            Extension_2__c=createExtentionInfo().Id,
            Extension_Quantity_2__c=2,
            Extension_Unit_2__c='TO',
            Extension_3__c=createExtentionInfo().Id,
            Extension_Quantity_3__c=2,
            Extension_Unit_3__c='TO'
        );
        insert OI;
       
        createBillingCreditWithoutDN(acc.Id,OI.LoadingPoint__c,OI.Product2Id,null,700,null);
        createBillingCreditWithoutDN(acc.Id,OI.LoadingPoint__c,OI.Product2Id,2,null, 'KG');


        //createBillingCreditWithoutDN(acc.Id,OI.LoadingPoint__c,OI.Product2Id,0,300, null);
        

        
        return OI;
    }
    
    public static OrderItem createChemicalOrderItem(Order recOrder,Id ProducthierarchyId,Id LoadingPointId){
        Account acc = [SELECT Id FROM Account WHERE Id=:recOrder.AccountId];
        
        List<contact> con= createAndInsertContactsForTesting(acc.Id,2);
        // Creeate Opportunity (alredy inserted in data factory)
        Opportunity opp = createOpportunityForTesting(acc);
        
        //Create Product (not inserted in data factory)
        Product2 prod = createProductForTesting(1)[0];
        prod.Product_hierarchy__c=ProducthierarchyId;
        prod.External_Id__c='99'+ prod.External_Id__c;
        prod.Sap_Number__c=prod.External_Id__c;
        insert prod;
        
        // Create Price Book Entry (alredy inserted in data factory)
        PricebookEntry pbe = createPriceBookEntryForTesting(prod);
        
        // Create IL_Price_Book
        IL_Price_Book__c ilpb = createIlChemicalPriceBookForTesting(prod.id,recOrder.AccountId);
        ilpb.Account__C=acc.Id;
        update ilpb;
        
        orderItem OI =new orderItem(
            orderId=recOrder.Id,
            DischargeLocation__c=createDischargeLocation(acc).Id,//create
            LoadingPoint__c=LoadingPointId!=null?LoadingPointId:createLoadingPoint('ספק').Id,//create
            PricebookEntryId=pbe.Id,
            Price_from_customer_order__c=null,
            Product2Id=prod.Id,
            Quantity=8,
            Status__c='10',
            triggerProcessor__c=false,
            UnitOfMeasure__c='TO',
            UnitPrice=0,
            Extension_1__c=createExtentionInfo().Id,
            Extension_Quantity_1__c=1,
            Extension_Unit_1__c='TO',
            Extension_2__c=createExtentionInfo().Id,
            Extension_Quantity_2__c=2,
            Extension_Unit_2__c='TO',
            Extension_3__c=createExtentionInfo().Id,
            Extension_Quantity_3__c=2,
            Extension_Unit_3__c='TO'
        );
        insert OI;
        

        return OI;
    }

    public static OrderItem createOrderItemWithAllDependenciesForTesting(){

        // Create Account (alredy inserted in data factory)
        List<Account> acc = createAccountForTesting(2);
        
        // Creeate Opportunity (alredy inserted in data factory)
        Opportunity opp = createOpportunityForTesting(acc[0]);
        
        //Create Product (not inserted in data factory)
        Product2 prod = createProductForTesting(1)[0];
        prod.dangerous_substance__c=true;
        prod.Product_hierarchy__c=createMasterProducthierarchy().Id;
        insert prod;
        
        // Create Price Book Entry (alredy inserted in data factory)
        PricebookEntry pbe = createPriceBookEntryForTesting(prod);
        
        // Create IL_Price_Book
        IL_Price_Book__c ilpb = createIlPriceBookForTesting(prod.id);
        
        //create Loading Point 
        LoadingPoint__c LP=createLoadingPoint('ספק');

        //Create Order
        order newOrder = new order(
            AccountId =acc[0].Id,
            EffectiveDate=system.today(),
            IntermediaryWarehouse__c=null,
            LabTestId__c=null,
            NonFreightCharge__c=false,
            Paying_Customer__c=acc[1].Id,
            Pricebook2Id=pbe.Pricebook2Id,
            PrivateTransport__c=false,
            RequestedSupplyDate__c=system.today().addDays(2),
            Status='10',
            TransactionType__c='30'
        );
        insert newOrder;
        orderItem OI =new orderItem(
            orderId=newOrder.Id,
            DischargeLocation__c=null,//create
            LoadingPoint__c=LP.Id,
            PricebookEntryId=pbe.Id,
            Price_from_customer_order__c=null,
            Product2Id=prod.Id,
            Product2=prod,
            Quantity=5,
            Status__c='10',
            triggerProcessor__c=false,
            UnitOfMeasure__c='TO',
            UnitPrice=0
        );
        insert OI;
          orderItem OI1 =new orderItem(
            orderId=newOrder.Id,
            DischargeLocation__c=null,//create
            LoadingPoint__c=LP.Id,
            PricebookEntryId=pbe.Id,
            Price_from_customer_order__c=null,
            Product2Id=prod.Id,
            Quantity=5,
            Status__c='10',
            triggerProcessor__c=false,
            UnitOfMeasure__c='TO',
            UnitPrice=0
        );
        insert OI1;
        
        return OI;
    }
    
    public static OrderStaging__c createOrderStaging(string OSType){
        orderItem OI = createOrderItemWithAllDependenciesForTesting();
        OrderStaging__c os = new OrderStaging__c();
        os.OrderItemId__c=OI.id;
        os.Order__c=OI.OrderId;
        os.Interface_Type__c=OSType;
        os.LineNumber__c='543284';
        os.OrderItemStatus__c ='30';
        os.Truck_code__c='ads6213218';
        return os;     
    }
    
    public static PermissionSetAssignment createPermissionAssignment(Id PermissionSetId, Id groupOrUser){
        PermissionSetAssignment  newPSA = new PermissionSetAssignment(AssigneeId = groupOrUser,PermissionSetId=PermissionSetId);
        insert newPSA;
        return newPSA;
    }
    
    public static Delivery_Note_Staging__c createDeliveryNoteStaging(orderItem OI, string UOM){
        
        Delivery_Note_Staging__c DNS= new Delivery_Note_Staging__c(
            AmountOfWeightingInGate__c	= 1000,
            Crane__c					= false,
            DeliveryCompanyName__c		= 'companyTest',
            DeliveryNoteLineId__c		= '10063-64',
            DeliveryNoteLineNo__c		= '64',
            DeliveryNoteNo__c			= '10063',
            DischargeQuantity__c		= 20,
            dischargeWeightInTon__c		= 5.72,
            DriverName__c				= 'בדיקה מכלית1',
            LoadingPoint__c				= OI.LoadingPointSapId__c,
            LoadingQuantity__c			= 20,
            LoadingSlipNumber__c		= '100068',
            meter__c					= false,
            OrderItemId__c				= OI.Id,
            TruckName__c				= '4567894',
            TruckNumber__c				= '4567894',
            UnitOfMeasure__c			= 'TO',
            Dischargequantityuom__c		= UOM, 
            Account__c					= OI.OrderAccount__c
        );
        
        insert DNS;
        
        
        return DNS;
        
    }
    
    public static Billing_Credit__c createBillingCreditWithoutDN(Id acc,Id LoadingPoint,Id Product,decimal Quantity, decimal sum, string UnitMeasure){
        Billing_Credit__c BC= new Billing_Credit__c(
            Account__c	=acc,
            Action_Type__c	='40',
            Comment__c='test BC',
            Loading_Point__c	=LoadingPoint,
            Paying_Customer__c=acc,
            Product__c=Product,
            Sum__c=sum,
            status__c='30',
            Reason__c='קידום מכירות'
        );
        
        insert BC;
        SYSTEM.debug(LOGGINGLEVEL.ERROR, 'New Billing credit created:'+BC);
        return BC;
    }
    
    public static list<Account> createFlexiableAccountForTesting(final Integer NUM_OF_ACCOUNTS_TO_CREATE, string Industry) {
        List<String> srcSys = AccountStagingTriggerHelper.sourceSys;
        List<Account> accList = new List<Account>();
        
        for (Integer i = 0; i < NUM_OF_ACCOUNTS_TO_CREATE; i++) {
            Account acc = new Account();
            acc.Name = NUM_OF_ACCOUNTS_TO_CREATE == 1 ? 'Test Account' : 'Test Account ' + i;
            acc.Classification__c = 'גדול';
            acc.Industry =Industry;
            acc.Sap_Number__c = String.valueOf(Integer.valueof((Math.random() * 1000000)));
            acc.AccountSource = srcSys[Math.mod(i,srcSys.size())];
            acc.External_Id__c = acc.AccountSource == 'FER' ? acc.Sap_Number__c : null;
            acc.Amfert_SAP_number__c = acc.AccountSource == 'AMF' ? acc.Sap_Number__c : null;
            acc.IBP_SAP_number__c = acc.AccountSource == 'IBP' ? acc.Sap_Number__c : null;
            acc.QAD1_sap_C__c = acc.AccountSource == 'QAD' ? acc.Sap_Number__c : null;
            acc.BRAZIL_SAP_NUMBER__c = acc.AccountSource == 'BRA' ? acc.Sap_Number__c : null;
            acc.US_SAP_NUMBER__c = acc.AccountSource == 'PLP' ? acc.Sap_Number__c : null;
            acc.India_Thali_Number__c = acc.AccountSource == 'E0228' ? acc.Sap_Number__c : null;
            acc.lAND__c = acc.AccountSource == 'E0035' ? acc.Sap_Number__c : null;
            acc.TRK_SAP__c = acc.AccountSource == 'TRK' ? acc.Sap_Number__c : null;
            acc.Fun_erp_number__c = acc.AccountSource == 'FNT' ? acc.Sap_Number__c : null;
            accList.add(acc);
        }
        insert accList;
        return accList;
    }
    
    /*Methods for Fert Jobs*/
    public static Opportunity createFertOpportunityForTesting(PricebookEntry pbe,Account acc,Product2 prod) {
        Opportunity opp = new Opportunity(
            AccountId = acc.Id,
            Name = 'Test Oppertunity',
            StageName = 'Prospecting',
            CloseDate = Date.today()
        );
        insert opp;
        
        /*create Opp Job Line*/
        OpportunityLineItem oli = new OpportunityLineItem(
            PriceBookEntryId = pbe.Id,
            OpportunityId = opp.Id,
            Product2Id = prod.Id,
            Plot_Size__c =80,
            unitPrice = 1, // Actually should be  quantity * pbe.UnitPrice
            Date__c = Date.newinstance(Date.today().year(), Date.today().month(), Date.today().day())
        );
        
        /*Create fert lineItem*/
        OpportunityLineItem oliFert = new OpportunityLineItem(
            PriceBookEntryId = pbe.Id,
            OpportunityId = opp.Id,
            Product2Id = prod.Id,
            Quantity_per_hectare__c = 10,
            Unit_of_measure__c = 'TO',
            unitPrice = 1, // Actually should be  quantity * pbe.UnitPrice
            Date__c = Date.newinstance(Date.today().year(), Date.today().month(), Date.today().day())
        );
        return opp;
    }
    
    public static Delivery_Note_Staging__c createFertDeliveryNoteStaging(string transactionType){
        List<Account> newAcc=createAccountForTesting(2);
        List<Product_hierarchy__c> allph= new List<Product_hierarchy__c>([SELECT Id FROM Product_hierarchy__c LIMIT 1  ]);
        List<LoadingPoint__c> allLP= new List<LoadingPoint__c>([SELECT Id FROM LoadingPoint__c LIMIT 1  ]);
        
        Product_hierarchy__c ph= allph.isEmpty()?createMasterProducthierarchy():allph[0];
        order orderRec= TestDataFactory_Test.createFertJobOrder(newAcc[0],newAcc[1]);
        
        LoadingPoint__c LP= allLP.isEmpty()?createLoadingPoint('ספק'):allLP[0];
        
        orderItem orderItemRec= TestDataFactory_Test.createFertJobOrderItem(newAcc[0],orderRec,ph.Id,LP.Id);
        orderRec.TransactionType__c=transactionType;
        update orderRec;  
        
        Delivery_Note_Staging__c DNS= new Delivery_Note_Staging__c(
            Account__c					=orderRec.accountId,
            AmountOfWeightingInGate__c	= 1000,
            Crane__c					= false,
            DeliveryCompanyName__c		= 'companyTest',
            DeliveryNoteLineId__c		= '10063-64',
            DeliveryNoteLineNo__c		= '64',
            DeliveryNoteNo__c			= '10063',
            DischargeQuantity__c		= 5,
            dischargeWeightInTon__c		= 5,
            DriverName__c				= 'בדיקה מכלית1',
            LoadingPoint__c				= orderItemRec.LoadingPointSapId__c,
            LoadingQuantity__c			= 5,
            LoadingSlipNumber__c		= '100068',
            meter__c					= false,
            OrderItemId__c				= orderItemRec.Id,
            TruckName__c				= '4567894',
            TruckNumber__c				= '4567894',
            UnitOfMeasure__c			= 'TO'
        );
        insert DNS;
        return DNS;
    }

 public static order createFertJobOrder(Account acc ,Account payingCust ){

        //Create Order
        order newOrder = new order(
            AccountId =acc.Id,
            EffectiveDate=system.today(),
            IntermediaryWarehouse__c=null,
            LabTestId__c=null,
            NonFreightCharge__c=false,
            Paying_Customer__c=payingCust.Id,
            Pricebook2Id=Test.getStandardPricebookId(),
            PrivateTransport__c=false,
            RequestedSupplyDate__c=system.today().addDays(2),
            Status='30',
            TransactionType__c='50'
            
        );
        insert newOrder;
        return newOrder;
    }
    
    public static OrderItem createFertJobOrderItem( Account acc,Order recOrder, Id ProductHierarchyId, Id loadingPointId){
        
        /*Create Product*/
        Product2 prod = createProductForTesting(1)[0];
        prod.Product_hierarchy__c=ProductHierarchyId;
        prod.Fertilize_Job_number_of_product__c='2';
        prod.External_Id__c='s1223123';
        prod.Sap_Number__c='s1223123';
        insert prod;
        /*fert*/
        Product2 prod1 = createProductForTesting(1)[0];
        prod1.Product_hierarchy__c=ProductHierarchyId;
        prod1.External_Id__c='66612213';
        prod1.Sap_Number__c='66612213';
        insert prod1;
        
        // Create Price Book Entry (alredy inserted in data factory)
        PricebookEntry pbe = createPriceBookEntryForTesting(prod);
        PricebookEntry pbe1 = createPriceBookEntryForTesting(prod1);
        
        
        // Create IL_Price_Book
        IL_Price_Book__c ilpb = createIlPriceBookForTesting(prod.id);
        IL_Price_Book__c ilpb1 = createIlPriceBookForTesting(prod1.id);
        
        /*Create Opportunity*/
        Opportunity opp = createFertOpportunityForTesting(pbe,acc,prod);
    

        orderItem OI =new orderItem(
            orderId=recOrder.Id,
            DischargeLocation__c=createDischargeLocation(acc).Id,//create
            LoadingPoint__c=loadingPointId!=null?loadingPointId:createLoadingPoint('ספק').Id,//create
            PricebookEntryId=pbe.Id,
            Price_from_customer_order__c=null,
            Product2Id=prod.Id,
            Quantity=80,
            Status__c='30',
            triggerProcessor__c=false,
            UnitOfMeasure__c='TO',
            UnitPrice=0
           
        );
        insert OI;
        
          orderItem OIFert =new orderItem(
            orderId=recOrder.Id,
            DischargeLocation__c=createDischargeLocation(acc).Id,//create
            LoadingPoint__c=loadingPointId!=null?loadingPointId:createLoadingPoint('ספק').Id,//create
            PricebookEntryId=pbe.Id,
            Price_from_customer_order__c=null,
            Product2Id=prod.Id,
            Quantity=2400,
            Status__c='30',
            triggerProcessor__c=false,
            UnitOfMeasure__c='TO',
            UnitPrice=0
           
        );
        insert OIFert;
        return OI;
    }
    

}