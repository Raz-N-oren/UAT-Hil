@isTest
public class MultiRecordsApprovalController_Test {
    
    
    public testmethod static void ILPriceBookApproval_Test(){
        system.runAs(new user(ID = UserInfo.getUserID())){
            PermissionSet getPermissionId = [SELECT Id FROM PermissionSet WHERE Name='F_C_Sub_Admin' limit 1];
            List<PermissionSetAssignment> PSAExist = [SELECT Id 
                                                FROM PermissionSetAssignment 
                                                WHERE AssigneeId=:userInfo.getUserId() 
                                                AND PermissionSetId=:getPermissionId.Id];
            if(PSAExist==null)
                PermissionSetAssignment PSA= TestDataFactory_Test.createPermissionAssignment(getPermissionId.Id,userInfo.getUserId());
        }
        
        // Create Account (alredy inserted in data factory)
        Account acc = TestDataFactory_Test.createAccountForTesting(1)[0];
        acc.Industry='לקוחות כימיקלים';
        update acc;
        // Creeate Opportunity (alredy inserted in data factory)
        Opportunity opp = TestDataFactory_Test.createOpportunityForTesting(acc);
        opp.Status__c='Draft';
        update opp;
        
        //Create Product (not inserted in data factory)
        Product2 prod = TestDataFactory_Test.createProductForTesting(1)[0];
        insert prod;
        
        // Create Price Book Entry (alredy inserted in data factory)
        PricebookEntry pbe = TestDataFactory_Test.createPriceBookEntryForTesting(prod);
        
        
        // Create IL_Price_Book
        IL_Price_Book__c ilpb = TestDataFactory_Test.createIlPriceBookForTesting(prod.id);
        ilpb.Account__c=acc.Id;
        ilpb.Product_Family_new__c=TestDataFactory_Test.createMasterProducthierarchy().Id;
        ilpb.Loading_Point__c=TestDataFactory_Test.createLoadingPoint('30').Id;
        ilpb.Opportunity__c=opp.Id;
        update  ilpb;
        
        OpportunityLineItem oli = TestDataFactory_Test.createOpportunityLineItemForTesting(  acc, opp,  prod, pbe);
        oli.Loading_Point__c= ilpb.Loading_Point__c;
        insert oli;
        opp.Scope__c='כימיקלים';
        update opp;
        
        
        
        // Create an approval request for IL Price Book
        Approval.ProcessSubmitRequest req =new Approval.ProcessSubmitRequest();
        req.setComments('Submitting request for approval.');
        req.setObjectId(ilpb.Id);
        req.setSubmitterId(userInfo.getUserId()); 
        req.setProcessDefinitionNameOrId('Price_Book_Approval');
        req.setSkipEntryCriteria(true);
        // Submit the approval request for the IL Price Book
        Approval.ProcessResult result = Approval.process(req);
  
        ProcessInstanceWorkitem wi=[SELECT ProcessInstanceId , ProcessInstance.TargetObjectId FROM ProcessInstanceWorkitem WHERE ProcessInstance.TargetObjectId=:ilpb.Id];
        
        MultiRecordsApprovalController.getSubmittedRecords();
        string json=  '[{"comments":"","recDescription":"יש ללחוץ על הכותרת של האישור","recordId":"'+ilpb.Id+'","recordName":"'+ilpb.Name+'","relatedTo":"New Product request","submittedBy":"ronen goldstain","submittedDate":"20/12/2022, 6:57","submittercomment":"No comments from submitter","workItemId":"'+wi.iD+'"}]';
        MultiRecordsApprovalController.processRecords('Approve',json);
        
    }
    
    public testmethod static void OppApproval_Test(){
        
        // Create Account (alredy inserted in data factory)
        Account acc = TestDataFactory_Test.createAccountForTesting(1)[0];
        acc.Industry='לקוחות כימיקלים';
        update acc;
        // Creeate Opportunity (alredy inserted in data factory)
        Opportunity opp = TestDataFactory_Test.createOpportunityForTesting(acc);
        opp.Status__c='Draft';
        update opp;
        
        //Create Product (not inserted in data factory)
        Product2 prod = TestDataFactory_Test.createProductForTesting(1)[0];
        insert prod;
        
        // Create Price Book Entry (alredy inserted in data factory)
        PricebookEntry pbe = TestDataFactory_Test.createPriceBookEntryForTesting(prod);
        
        // Create IL_Price_Book
        IL_Price_Book__c ilpb = TestDataFactory_Test.createIlPriceBookForTesting(prod.id);
        ilpb.Account__c=acc.Id;
        ilpb.Loading_Point__c=TestDataFactory_Test.createLoadingPoint('30').Id;
        ilpb.Opportunity__c=opp.Id;
        update  ilpb;
        
        OpportunityLineItem oli = TestDataFactory_Test.createOpportunityLineItemForTesting(  acc, opp,  prod, pbe);
        oli.Loading_Point__c= ilpb.Loading_Point__c;
        insert oli;
        opp.Scope__c='כימיקלים';
        update opp;
        
        // Create an approval request for opp
        Approval.ProcessSubmitRequest req1 =new Approval.ProcessSubmitRequest();
        req1.setComments('Submitting request for approval.');
        req1.setObjectId(opp.Id);
        req1.setSubmitterId(userInfo.getUserId()); 
        req1.setProcessDefinitionNameOrId('Opportunity_Manager_approval_process');
        req1.setSkipEntryCriteria(true);
        
        // Submit the approval request for the opp
        Approval.ProcessResult result1 = Approval.process(req1);
        
        MultiRecordsApprovalController.getSubmittedRecords();
        
        // string json='[{"comments":"test","customerLocation":"IL Beer Sheva - Yanek","customerName":"lilach.mi@sd.icl.com.staging","incidentCreatedDate":"07/04/2022 14:59","incidentDescription":"TEST LILACH","recordId":"/'+inc.Id+'","recordName":"00501983 &#124; Incident","relatedTo":"Lilach Mis","submittedBy":"Lilach Mis","submittedDate":"23/04/2022 22:50","submittercomment":"No comments from submitter","workItemId":"'+newWorkItemIds[0]+'","isChecked":true}]';
        // MultiRecordsApprovalController.processRecords('Approve',json);
        
    }
    
    public testmethod static void DiscountMatrixApproval_test(){
        Discount_Matrix__c recDM= TestDataFactory_Test.createDisMatForTesting();
        List<Discount_matrix_Line__c>  recDML = TestDataFactory_Test.createDisMatLineForTesting(recDM.Id,2);
        
        // Create an approval request for IL Price Book
        Approval.ProcessSubmitRequest req =new Approval.ProcessSubmitRequest();
        req.setComments('Submitting request for approval.');
        req.setObjectId(recDM.Id);
        req.setSubmitterId(userInfo.getUserId()); 
        req.setProcessDefinitionNameOrId('Discount_Matrix_Approval_Process');
        req.setSkipEntryCriteria(true);
        
        Approval.ProcessResult result = Approval.process(req);
        MultiRecordsApprovalController.getSubmittedRecords();
    }
    
    public testmethod static void NewProductRequest_test(){
        New_Product_request__c NPR= TestDataFactory_Test.createNewProduct();
        
        // Create an approval request for IL Price Book
        Approval.ProcessSubmitRequest req =new Approval.ProcessSubmitRequest();
        req.setComments('Submitting request for approval.');
        req.setObjectId(NPR.Id);
        req.setSubmitterId(userInfo.getUserId()); 
        req.setProcessDefinitionNameOrId('IL_Sales_manager_Chemicals');
        req.setSkipEntryCriteria(true);
        
       // Approval.ProcessResult result = Approval.process(req);
        MultiRecordsApprovalController.getSubmittedRecords();
    }
    
    public testmethod static void NewDiscount_test(){
        
        // Create Account (alredy inserted in data factory)
        Account acc = TestDataFactory_Test.createAccountForTesting(1)[0];
        acc.Setelment__c= TestDataFactory_Test.createSettelment().Id;
        acc.Industry='לקוחות כימיקלים';
        update acc;
        // Creeate Opportunity (alredy inserted in data factory)
        Opportunity opp = TestDataFactory_Test.createOpportunityForTesting(acc);
        opp.Status__c='Draft';
        update opp;
        
        //Create Product (not inserted in data factory)
        Product2 prod = TestDataFactory_Test.createProductForTesting(1)[0];
        prod.Product_hierarchy__c = TestDataFactory_Test.createMasterProducthierarchy().Id;
        insert prod;
        
        // Create Price Book Entry (alredy inserted in data factory)
        PricebookEntry pbe = TestDataFactory_Test.createPriceBookEntryForTesting(prod);
        
        Discount__c dis= TestDataFactory_Test.createNewDiscount(acc.Id,prod.Id);
        dis.Product_Family_new__c =prod.Product_hierarchy__c;
        dis.Settlement__c =  acc.Setelment__c;
        insert dis;
 
        MultiRecordsApprovalController.getSubmittedRecords();
    }
    
}