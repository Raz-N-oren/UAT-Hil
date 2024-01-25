@isTest
public class BillingCredit_RelatedDNInfo_Test {

    @testSetup static void createData(){
        Product_hierarchy__c ph= TestDataFactory_Test.createMasterProducthierarchy();
        LoadingPoint__c LP= TestDataFactory_Test.createLoadingPoint('ספק');
        //מכירה ממחסן קונסיגנציה
        order orderRec= TestDataFactory_Test.createOrder();
        orderRec.Payer_Approval__c='123123';
        orderRec.TransactionType__c='20';
        orderItem orderItemRec= TestDataFactory_Test.createOrderItem(orderRec,ph.Id, LP.Id);
        update orderRec;  
        Delivery_Note_Staging__c DNS=TestDataFactory_Test.createDeliveryNoteStaging(orderItemRec,'TO');
        
        // מכירה ישירה
        order orderRec1= TestDataFactory_Test.createChemicalOrder();
        orderRec1.Payer_Approval__c='123123';
        orderRec1.TransactionType__c='30';
        orderRec1.SapValidationsPerformed__c=true;
        orderRec1.Status='30';
        insert orderRec1;   
        orderItem orderItemRec1= TestDataFactory_Test.createOrderItem(orderRec1,ph.Id, LP.Id);
        Delivery_Note_Staging__c DNS1=TestDataFactory_Test.createDeliveryNoteStaging(orderItemRec1,'EA');
        update DNS1;
    }
    public static testMethod void checkTotalCreditForDNTest(){
        Set<String> SobjectFields = Schema.getGlobalDescribe().get('DeliveryNote__c').getDescribe().fields.getMap().keySet();    
        List<String> fieldsInList = new List<String>(SobjectFields);
        string query ='SELECT ' + String.join(fieldsInList, ',') + ' FROM DeliveryNote__c';
        List<DeliveryNote__c> DNTest = Database.query(query);
        
        BillingCredit_RelatedDNInfo.checkTotalCreditForDN(DNTest[0].Id, 3, 'TO', NULL);
        BillingCredit_RelatedDNInfo.checkTotalCreditForDN(DNTest[0].Id,null,null, 560);
        
        Billing_Credit__c BC= new Billing_Credit__c(
            Account__c			= DNTest[0].Account__c,
            Delivery_Note__c	= DNTest[0].Id,
            Action_Type__c	  	= '40',
            Comment__c			= 'test BC',
            Loading_Point__c	= DNTest[0].LoadingPoint__c,
            Paying_Customer__c	= DNTest[0].Account__c,
            Product__c			= DNTest[0].Product__c,
            Quantity__c			= 5,
            Unit_of_measure__c	= 'TO',
            status__c			= '30',
            Reason__c			= 'קידום מכירות'
        );
        insert BC;
        
        Billing_Credit__c BC1= new Billing_Credit__c(
            Account__c			= DNTest[0].Account__c,
            Delivery_Note__c	= DNTest[0].Id,
            Action_Type__c	  	= '40',
            Comment__c			= 'test BC',
            Loading_Point__c	= DNTest[0].LoadingPoint__c,
            Paying_Customer__c	= DNTest[0].Account__c,
            Product__c			= DNTest[0].Product__c,
            Sum__c				= 600,
            status__c			= '30',
            Reason__c			= 'קידום מכירות'
        );
        insert BC1;
       
    }

}