@isTest
public class getPicklistLabel_Controller_Test {
    
    private static testMethod void getPicklistLabel_Test(){
        test.startTest();
        test.setMock(HttpCalloutMock.class, new TankInterfaceMock());
        order orderRec= TestDataFactory_Test.createOrder();
        getPicklistLabel_Controller PicklistValueIns =new getPicklistLabel_Controller();
        //Set controller params
        PicklistValueIns.fieldApiName='TransactionType__c';
        PicklistValueIns.ObjApiName='order';
        PicklistValueIns.recordId=orderRec.Id;
        
         string picklistValue =PicklistValueIns.getPicklistLabel();
        
        
        //call Aura function
        string picklistValueAura =getPicklistLabel_Controller.getPicklistLabel('TransactionType__c', 'order', orderRec.Id) ;    
        system.debug(loggingLevel.ERROR, 'picklistValue:'+picklistValue);
        test.stopTest();
    }    

}