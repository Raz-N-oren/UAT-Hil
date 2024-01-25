global with sharing class OrderStaging_RunFailureRows implements Schedulable {
    global void execute(SchedulableContext ctx) {
        Map<String, Object> Params = new Map<String, Object>();
        Params.put('recordId','006p000000Aal2EAAR');
        Flow.Interview.OrderStaging_Resend_Request_because_of_failure stage = new Flow.Interview.OrderStaging_Resend_Request_because_of_failure(Params);
        stage.start();
    }    
      global void finish(){
          OrderStaging_RunFailureRows OSF = new OrderStaging_RunFailureRows();
          String cronexpression = '0 15 * * * ?';
          String strJobName = 'Job-OrderStaging_RunFailureRows Next Run:'+system.now().addMinutes(10);
          if(!Test.isRunningTest()){
              System.schedule(strJobName, cronexpression, OSF);
          }
      }
}