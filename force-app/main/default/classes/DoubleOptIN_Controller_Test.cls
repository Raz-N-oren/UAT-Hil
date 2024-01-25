@isTest
public class DoubleOptIN_Controller_Test {
    public static testmethod void createNewDOI(){
        Digital_Input__c DIRec= new Digital_Input__c(
            Company__c='test Company',
            Country__c='Germany',
            Email__c='testUser@testcompany.com',
            Last_Name__c='LastNameTest',
            Mobile__c='098986565465'
        );
        
        insert DIRec;
        
        
        test.startTest();
        DoubleOptIN_Controller.createNewDOI(DIRec.Email__c, true, (string.valueOf(DIRec.Id).substring(0,15)));
        String jobID =system.scheduleBatch(new DoubleOPTInScheduledBatch(), 'test', 10);

        test.stopTest();
    }
}