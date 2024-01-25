@isTest
public class priceCalculationInfo_Test {
    
    public static testMethod void  getPriceBookRec_Test(){
        Account acc = TestDataFactory_Test.createAccountForTesting(1)[0];
        acc.Industry='לקוחות כימיקלים';
        update acc;
        Product_hierarchy__c ph= TestDataFactory_Test.createMasterProducthierarchy();
        LoadingPoint__c LP= TestDataFactory_Test.createLoadingPoint('ספק');
        
        order orderRec= TestDataFactory_Test.createOrder();
        orderItem orderItemRec= TestDataFactory_Test.createOrderItem(orderRec,ph.Id, LP.Id);
        IL_Price_Book__c ipb =createGenericChemicalsPB(orderRec.AccountId,orderItemRec.Product2Id,'below',10,20,null,'Regular');
        IL_Price_Book__c ipb1 =createGenericChemicalsPB(orderRec.AccountId,orderItemRec.Product2Id,'below',5,30,orderItemRec.LoadingPoint__c,null);

        priceCalculationInfo.getPrice(orderItemRec.Product2Id,orderRec.AccountId,'כימיקלים','KG',6,orderItemRec.LoadingPoint__c,orderItemRec.TransportType__c,null,null);
        priceCalculationInfo.getPrice(orderItemRec.Product2Id,orderRec.AccountId,'כימיקלים','M3',6,null,'Regular',null,null);
        priceCalculationInfo.getPrice(orderItemRec.Product2Id,orderRec.AccountId,'כימיקלים','LTR', 650,null,null,null,null);


    }
    
    public static IL_Price_Book__c createGenericChemicalsPB(Id account, Id productId, string belowAbove,Decimal belowAboveQuantity,Decimal fixedPrice,Id loadingId,string transportType){
        IL_Price_Book__c ipb = new IL_Price_Book__c(
            Account__c=account,
            Loading_Point__c=loadingId,
            Product_Service__c=productId,
            Fixed_Price__c = fixedPrice,
            Start_Date__c = system.today().addDays(-2),
            End_Date__c = system.today().addyears(1),
            Status__c = 'תקף',
            transport_Type__c=transportType,
            Unit_Of_Meager__c = 'TO',
            OverBelowAmount__c=belowAbove,
            OverBelowQuantity__c=belowAboveQuantity
        );
        
        insert ipb;
        return ipb;
    }
}