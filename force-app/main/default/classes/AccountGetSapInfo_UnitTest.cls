@isTest
public class AccountGetSapInfo_UnitTest {
    
    @TestSetup
    public static void setupData() {
        Account acc = TestDataFactory_Test.createAccountForTesting(1)[0];
        system.debug('acc info: '+acc);
    }
    
    @isTest
    public static void GetAccountSapInfoTest(){
        Account acc = [SELECT Id, Name From Account][0];
        system.debug('acc2 info: '+acc);
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new AccountGetSapInfoMock() );
        AccountGetSapInfo.GetAccountSapInfo( acc.Id );
        Test.stopTest();
    }
}