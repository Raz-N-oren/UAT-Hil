@isTest
private class VisitReportPDFActionsExtension_Test {
  @isTest
  private static void VisitReportPDFActionsExtension_Test1() {
    
    Account acc = new Account(Name='Account Test');
    insert acc;
    Visit_Report__c vr = new Visit_Report__c(Account__c = acc.Id);
    insert vr;

    Test.startTest(); 
    VisitReportPDFActionsExtension.savePDF(vr.Id, 'Testing');
    Test.stopTest(); 

  }
}