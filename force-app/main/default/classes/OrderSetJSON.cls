/* Class Name:OrderSetJSON
* Description: builds the order JSON to HOVALOT system 
*/
public with sharing class OrderSetJSON {
    private List<Order> newTrigger                      = new List<Order>();
    private Set<Id> setJSONIds                          = new Set<Id>();//orders ready for Interface
    private Set<Id> AccountIds                          = new Set<Id>();
    private Set<Id> branchIds                           = new Set<Id>();
    private Set<Id> contactIds                          = new Set<Id>();
    
    private Set<Id> ProductIds                          = new Set<Id>();
    private map<Id,OrderItem> RelatedOrderItem          = new map<Id,OrderItem>();
    private map<Id,Branch_Contact_Link__c> RelatedBranchContact = new map<Id,Branch_Contact_Link__c>();
    private Map<Id,Order> oldMap                        = (Map<Id,Order>)trigger.oldMap;
    private Map<string,string> OrderJSONFields          = new Map<string,string>();
    private Map<string,string> OrderItemJSONFields      = new Map<string,string>();
    private Map<string,string> ContactJSONFields        = new Map<string,string>();
    private Map<string,string> AccountJSONFields        = new Map<string,string>();
    private Map<string,string> ProductJSONFields        = new Map<string,string>();
    
    GeneralInterfaceData__mdt JSONFields                = [SELECT AccountFields__c,ContactFields__c,OrderFields__c,ProductFields__c,OrderItemFields__c
                                                           FROM GeneralInterfaceData__mdt
                                                           WHERE MasterLabel='Order'];
    
    public map<Id,string> getOrderSetJSON(List<Order> triggerNew){
        newTrigger=triggerNew;
        map<Id,string> returnMap = new map<Id,string>();
        
        setJSONIds();
        queryRelatedAccountInfo();
        queryRelatedOrderItem();
        BuildRelatedOrederItem();
        returnMap=  BuildOrderJSON();
        return returnMap;
        
    }
    
    private void setJSONIds(){
        if(setJSONIds.isEmpty()){
            for(order rec:newTrigger){
                if( !system.isFuture()){
                    order old = oldMap.get(rec.Id);
                    setJSONIds.add(rec.Id);
                    AccountIds.add(rec.AccountId);
                    if(rec.Branch_growth__c!=null)
                        branchIds.add(rec.Branch_growth__c); 
                }
            }
        }
    }
    
    private map<Id,string> BuildOrderJSON(){
        map<Id,string> returnMap = new map<Id,string>();
        string env ='"Env":"'+( string.valueOf(System.URL.getSalesforceBaseURL()).contains('uat')?'qa':'prod')+'",';

        string[] orderFields= JSONFields.OrderFields__c.split(';');
        string OrderJSON='';
        if(!setJSONIds.isEmpty()){
           
               
           
            for(Order rec:newTrigger){
                try{
                    OrderJSON='{"Order":{';
                    for(string fId:orderFields){
                        string value = string.valueOf(rec.get(fId))!=null?string.valueOf(rec.get(fId)).replace('"','\\"').removeEnd('\\'):'';
                        if(fId=='RequestedSupplyDate__c'){
                            date d= date.valueOf(rec.get(fId)); 
                            DateTime dt = DateTime.newInstance(d.year(), d.month(),d.day());
                            String dateStr = dt.format('yyyy-MM-dd')+'T00:00:00.000+00:00';
                            OrderJSON+= OrderJSON=='{"Order":{'?env+'"'+fId+'":'+'"'+string.valueOf(dateStr)+'"':+',"'+fId+'":'+'"'+dateStr+'"';                      
                        }
                     
                        else{
                            OrderJSON+= OrderJSON=='{"Order":{'?env+'"'+fId+'":'+'"'+value+'"':+',"'+fId+'":'+'"'+value+'"';
                        }
                        OrderJSONFields.put(fId, string.valueOf(rec.get(fId)));
                    }
                    system.debug(LoggingLevel.ERROR,'OrderJSON:'+OrderJSON);
                    OrderJSON+=AccountJSONFields.get(rec.AccountId);
                    system.debug(LoggingLevel.ERROR,'OrderJSON with Account Details:\n'+OrderJSON);
                    OrderJSON+=ContactJSONFields.get(rec.AccountId)+']';
                    orderJSON+=',"OrderLineItems":['+OrderItemJSONFields.get(rec.Id)+']}';
                    system.debug(LoggingLevel.ERROR,'OrderJSON with OrderItem Details:\n'+OrderJSON);
                    orderJSON= orderJSON.replaceAll('null', '');
                    orderJSON= orderJSON.replaceAll('\r', '\\r');
                    orderJSON= orderJSON.replaceAll('\n', '\\n');

                    system.debug(loggingLevel.ERROR,'JSON:'+OrderJSON);
                    returnMap.put(rec.Id,orderJSON);   
                    
                }
                catch( Exception  e){
                    rec.addError('Error:'+e.getMessage()+' \nCause:'+ e.getCause() );
                    
                }
            }
        }
        return returnMap;
    }
    
    private void queryRelatedAccountInfo(){
        string[] AccountFields= JSONFields.AccountFields__c.split(';');
        if(!AccountIds.isEmpty()){
            string soql = 'SELECT Description,'+JSONFields.AccountFields__c.replaceAll(';',',')+ ' FROM Account WHERE Id IN:AccountIds' ; 
            system.debug(loggingLevel.ERROR, 'soql:'+soql);
            for(Account rec:database.query(soql)){
                string AccountDetailsJSON ='';
                for(string fId:AccountFields){
                    IF(fId=='Description__c'){
                 		string accountDescription =rec.description!=null && rec.Description__c!=rec.description? string.valueOf(rec.get(fId))+'\\n'+rec.description:string.valueOf(rec.get(fId));
                        AccountDetailsJSON+=',"'+fId+'":'+'"'+(accountDescription!=null?accountDescription.replace('"','\\"').removeEnd('\\'):'')+'"';
                    }
                    else{
                        AccountDetailsJSON+=',"'+fId+'":'+'"'+(string.valueOf(rec.get(fId))!=null?string.valueOf(rec.get(fId)).replace('"','\\"').removeEnd('\\'):'')+'"';
                    }
                }
                AccountJSONFields.put(rec.Id,+AccountDetailsJSON);
                system.debug(LoggingLevel.ERROR,'AccountDetailsJSON:'+AccountDetailsJSON);
            }
            queryRelatedContacttInfo();
        }
    }
    
    private void queryRelatedContacttInfo(){
        queryRelatedBranchContacts();
        string[] ContactFields= JSONFields.ContactFields__c!=null?JSONFields.ContactFields__c.split(';'):null;
        if(ContactFields!=null){
            List<string> relatedContact;
            string filterSOQL =contactIds!=null && contactIds.size()>0?' AND Id IN: contactIds':' AND AccountId IN:AccountIds';
            string soql = 'SELECT AccountId,'+JSONFields.ContactFields__c.replaceAll(';',',')+ ' FROM Contact WHERE OperationalContact__c =TRUE '+filterSOQL; 
            system.debug(loggingLevel.ERROR, 'Contact soql:'+soql);
            string contactJSON ='},"RelatedContacts":[';
            for(Contact rec:database.query(soql)){
                contactJSON=ContactJSONFields.get(rec.AccountId)==null?contactJSON:',';
                for(Integer i = 0; i < ContactFields.size(); i++){
                    string value = string.valueOf(rec.get(ContactFields[i]))!=null?string.valueOf(rec.get(ContactFields[i])).replace('"','\\"').removeEnd('\\'):'';
                    string fId='"'+ContactFields[i]+'":'+'"'+value+'"';
                    contactJSON+=i==0?'{'+fId:','+fId;
                }
                contactJSON+='}';
                if(ContactJSONFields.get(rec.AccountId)==null)
                    ContactJSONFields.put(rec.AccountId,contactJSON);
                else{
                    ContactJSONFields.put(rec.AccountId,string.valueOf(ContactJSONFields.get(rec.AccountId))+contactJSON);
                }
            }
            system.debug(LoggingLevel.ERROR,'ContactJSONFields:'+ContactJSONFields);
        }
    }
 
    private void queryRelatedBranchContacts(){
        if( !branchIds.isEmpty()){
            for(Branch_Contact_Link__c recBreanch:[SELECT Contact__C FROM Branch_Contact_Link__c WHERE BranchGrowth__c IN:branchIds]){
                contactIds.add(recBreanch.contact__c);
            }
        }
    }
    
    private void queryRelatedOrderItem(){
        if(JSONFields.OrderItemFields__c!=null){
            string[] OrderItemFields=JSONFields.OrderItemFields__c.split(';');
            string soql = 'SELECT Product2Id ,LoadingPointSapId__c,LoadingPoint__r.Supplier_Sap_Id__c,LoadingPoint__r.LoadingPointType__c,'+JSONFields.OrderItemFields__c.replaceAll(';',',')+ ' FROM OrderItem WHERE OrderId IN:setJSONIds' ; 
            system.debug(loggingLevel.ERROR, 'queryRelatedOrderItem --soql :'+soql);
            try{
            RelatedOrderItem = new map<Id,orderItem>((List<orderItem>)Database.query(soql));
            }
            catch(DMLException e){
                
            }
            system.debug(loggingLevel.ERROR, 'RelatedOrderItem size:'+RelatedOrderItem.values());
            if(!RelatedOrderItem.isEmpty()){
                for(OrderItem getProductId:RelatedOrderItem.values()){
                    ProductIds.add(getProductId.Product2Id);
                }
                string[] ProductFields=JSONFields.ProductFields__c.split(';');
                string soqlProduct = 'SELECT '+JSONFields.ProductFields__c.replaceAll(';',',')+ ' FROM Product2 WHERE Id IN:ProductIds' ; 
                system.debug(loggingLevel.ERROR, 'soqlProduct:'+soqlProduct);
                for(Product2 rec:database.query(soqlProduct)){
                    string sapnum=rec.Sap_Number__c.replaceFirst( '^0+', '');
                    if(sapnum.startsWith('99')|| sapnum.startsWith('6')){
                        string ProductDetailsJSON ='';
                        for(string fId:ProductFields){
                            ProductDetailsJSON+=',"'+fId+'":'+'"'+(string.valueOf(rec.get(fId))!=null?string.valueOf(rec.get(fId)).removeEnd('\\'):'')+'"';
                        }
                        ProductJSONFields.put(rec.Id,+ProductDetailsJSON);
                    }
                }            
                system.debug(LoggingLevel.ERROR,'ProductJSONFields:'+ProductJSONFields);
            }
        }
    }
    
    private void BuildRelatedOrederItem(){
        if(JSONFields.OrderItemFields__c!=null){
            string OrderItemJSON ='';
            system.debug(LoggingLevel.ERROR,'RelatedOrderItem:'+RelatedOrderItem.size());
            Integer count=0;
            for(OrderItem rec:RelatedOrderItem.values()){
                count++;
                system.debug(LoggingLevel.ERROR,'OrderItem -- rec.OrderItemNumber:'+rec.OrderItemNumber);
                if(ProductJSONFields.get(rec.product2Id)!=null){
                    //set Order Item info
                    OrderItemJSON+=OrderItemJSON!=''?',':'';
                    system.debug(LoggingLevel.ERROR,'OrderItemJSON*'+count+':'+OrderItemJSON);
                    
                    OrderItemJSON+=(OrderItemJSONFields.get(rec.OrderId)==null?'':'')+setSobjectJSONFields(OrderItemJSON,JSONFields.OrderItemFields__c.split(';'),rec,'orderItem');
                    system.debug(LoggingLevel.ERROR,'OrderItemJSON-'+count+':'+OrderItemJSON);
                    
                    //add Product info
                    OrderItemJSON+=ProductJSONFields.get(rec.product2Id)+'}';
                    system.debug(LoggingLevel.ERROR,'OrderItemJSON+'+count+':'+OrderItemJSON);
                    
                    OrderItemJSONFields.put(rec.orderId,OrderItemJSON);
                    system.debug(LoggingLevel.ERROR,'OrderItemJSONFields values'+count+':'+OrderItemJSONFields.values());
                    
                }
            }
            system.debug(LoggingLevel.ERROR,'OrderItemJSONFields*****:'+OrderItemJSONFields);
        }
    }
    
    Private string setSobjectJSONFields(string JSONRec,List<string> sobjectFields, Sobject rec,string APIName){
        string newJSON='';
        system.debug(LoggingLevel.ERROR,'setSobjectJSONFields: start JSONRec'+JSONRec);
        
        for(Integer i = 0; i < sobjectFields.size(); i++){
            string fId='';
            if(APIName=='orderItem'){
                orderItem OI = (orderItem)rec;
                if(sobjectFields[i]=='LoadingPoint__c' ){
                    system.debug(loggingLevel.ERROR, 'סוג נקודת הפריקה: '+ OI.Id +'--'+OI.LoadingPoint__r.LoadingPointType__c);
                    if( OI.LoadingPoint__r.LoadingPointType__c=='ספק'){
                        fId='"'+sobjectFields[i]+'":'+'"'+string.valueOf(OI.LoadingPoint__r.Supplier_Sap_Id__c)+'"';
                    }
                    else{
                        fId='"'+sobjectFields[i]+'":'+'"'+string.valueOf(rec.get('LoadingPointSapId__c'))+'"';
                    }
                }
                else if( sobjectFields[i]=='TransactionType__c' && OI.LoadingPoint__r.LoadingPointType__c=='ספק'){
                    fId='"'+sobjectFields[i]+'":'+'"'+'90'+'"';
                    system.debug(loggingLevel.ERROR, 'fId: ספק'+ fId);
                }
                else{
                    string value = string.valueOf(rec.get(sobjectFields[i]))!=null?string.valueOf(rec.get(sobjectFields[i])).replace('"','\\"').removeEnd('\\'):'';

                    fId='"'+sobjectFields[i]+'":'+'"'+value+'"';
                }
            }
            newJSON+=i==0?'{'+fId:','+fId;
            system.debug(LoggingLevel.ERROR,'setSobjectJSONFields:JSONRec'+newJSON);
            
        }
        return newJSON;
    }
}