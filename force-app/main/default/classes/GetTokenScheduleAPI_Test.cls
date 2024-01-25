@isTest
public with sharing class GetTokenScheduleAPI_Test {
    @isTest
    static void getToken() {
        String CRON_EXP = '0 0 * * * ?'; // sec, min, hour...
        GetTokenScheduleAPI sch = new GetTokenScheduleAPI(); 
        
        Test.setMock(HttpCalloutMock.class, new GetTokenAPIMock());
        
        Test.startTest();
        System.schedule('Get Token for Mimshakim test', CRON_EXP, sch);
        Test.stopTest();
    }

    @isTest
    static void createUpdateMetadataUtilsTest() {
        Metadata.DeployCallback callback = new CreateUpdateMetadataUtils();
        Metadata.DeployResult result = new Metadata.DeployResult();
        result.status = Metadata.DeployStatus.Succeeded;

        Metadata.DeployCallbackContext context = new Metadata.DeployCallbackContext();

        Test.startTest();
        callback.handleResult(result , context);
        Test.stopTest();
    }
}