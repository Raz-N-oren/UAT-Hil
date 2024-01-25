public class getPicklistLabel_Controller {
    public string fieldApiName {get;set;}
    public string ObjApiName {get;set;}
    public string recordId {get;set;}
    
    public String getPicklistLabel() {
        system.debug(loggingLevel.ERROR, 'picklist recordId:'+recordId+ ' ObjApiName:'+ObjApiName+'  fieldApiName:'+fieldApiName);
        return queryLabel(fieldApiName,ObjApiName,recordId);
    }
      @AuraEnabled
    public static string getPicklistLabel(string fieldApi,string ObjApi,string recId){
        return queryLabel(fieldApi,ObjApi,recId);
    }
    
    private static string queryLabel(string fieldApi,string ObjApi,string recId){
        string label='';
        if(recId!=null && fieldApi!=null && ObjApi!=null){
            string soql = 'SELECT Id,toLabel('+fieldApi+ ') FROM '+ObjApi+ ' WHERE Id =:recId';
            system.debug(loggingLevel.ERROR, 'soql:'+soql);
            List<sobject> rec= new List<sobject>(database.query(soql));
            if(rec[0].get(fieldApi)!=null){
                system.debug(loggingLevel.ERROR, 'picklist label:'+string.valueOf(rec[0].get(fieldApi)));
                label=string.valueOf(rec[0].get(fieldApi)); 
            }
        }
        return label;
    }
    
  
}