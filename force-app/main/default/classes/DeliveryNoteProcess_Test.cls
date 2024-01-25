@isTest
public class DeliveryNoteProcess_Test {
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
        orderRec1.Payer_Approval__c='1231623';
        orderRec1.TransactionType__c='30';
        orderRec1.SapValidationsPerformed__c=true;
        orderRec1.Status='30';
        insert orderRec1;   
        orderItem orderItemRec1= TestDataFactory_Test.createOrderItem(orderRec1,ph.Id, LP.Id);
        Delivery_Note_Staging__c DNS1=TestDataFactory_Test.createDeliveryNoteStaging(orderItemRec1,'EA');
        update DNS1;
    }
   public static testMethod void createDeliveryNote(){
        test.startTest();
        List<Delivery_Note_Staging__c> createNew = new List<Delivery_Note_Staging__c>();
           Set<String> SobjectFields = Schema.getGlobalDescribe().get('DeliveryNote__c').getDescribe().fields.getMap().keySet();    
        List<String> fieldsInList = new List<String>(SobjectFields);
        string query ='SELECT ' + String.join(fieldsInList, ',') + ' FROM DeliveryNote__c';
        List<DeliveryNote__c> DNTest = Database.query(query);
        DNTest[0].InvoiceApproved__c=true;
        DNTest[1].InvoiceApproved__c=true;
        update DNTest[0];
        update DNTest[1];
        
        test.stopTest();
        DeliveryNote_SetJSONSapInvoice.FlowInputs  fi = new DeliveryNote_SetJSONSapInvoice.FlowInputs();
        fi.approvedDN=DNTest[0];
        DeliveryNote_SetJSONSapInvoice.CreateDeliveryNoteStaging(new List<DeliveryNote_SetJSONSapInvoice.FlowInputs>{fi});
        // getProductDiscount.upsertRelaventDeliveryNotes( TestDataFactory_Test.createNewDiscount(DNTest.Account__c,DNTest.Product__c));
    }
    
    public static testMethod void createFertDeliveryNote(){
        test.startTest();
        
        Delivery_Note_Staging__c DNSFert=TestDataFactory_Test.createFertDeliveryNoteStaging('50'); 
        
        test.stopTest();
        DeliveryNote__c DNTest = [SELECT Id,account__C,product__c,InvoiceApproved__c FROM DeliveryNote__c where order__r.transactionType__C='50' limit 1];
        DNTest.InvoiceApproved__c=true;
        update DNTest;

    }
}