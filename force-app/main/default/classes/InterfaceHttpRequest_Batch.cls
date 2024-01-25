/**
* @description       : 
* @author            : ChangeMeIn@UserSettingsUnder.SFDoc
* @group             : 
* @last modified on  : 03-19-2023
* @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
global class InterfaceHttpRequest_Batch implements Database.Batchable<sObject>,   Database.AllowsCallouts {
    set<Id> relatedRec= new set<Id>();
    set<Id> relatedRecsSuccsses= new set<Id>(); 
    string sobjectApi='';
    string query='';
    List<sobject> updateRec= new  List<sobject>();
    Map<Id,sobject> recsForUpdate = new Map<Id,sobject>();
    Map<Id,OrderStaging__c> existSuccses= new Map<Id,OrderStaging__c>();
    static Map<Id,OrderItem> orderItemsToUpdate = new Map<Id,OrderItem>();
    
    
    public InterfaceHttpRequest_Batch(string objApi,set<Id> recIds){
        sobjectApi=objApi;
        relatedRec=recIds;
        query=setDynamicQueryObj(sobjectApi,relatedRec);
        system.debug(loggingLevel.ERROR, 'relatedRec:'+relatedRec+'\n query:'+query+'\n sobjectApi:'+sobjectApi);
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        system.debug(loggingLevel.ERROR, 'setDynamicQueryObj:'+setDynamicQueryObj(sobjectApi,relatedRec));
        return Database.getQueryLocator(setDynamicQueryObj(sobjectApi,relatedRec));
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> records) {  
        system.debug(loggingLevel.ERROR, 'records size:'+records.size());
        try{ 
            for(sObject obj: records){
                sendInterface(obj);
            }
            System.debug('recsForUpdate:' + recsForUpdate.size());  
            list<Database.SaveResult> results = Database.update(recsForUpdate.values(), false);
            if(existSuccses.size()>0)
                orderStaging_UpdateOrderItem UpdateOrderItem= new orderStaging_UpdateOrderItem(existSuccses.values(),orderItemsToUpdate);
        }
        catch(Exception e) {         
            System.debug('Error:' + e.getMessage()+ e.getStackTraceString());  
        }
    }
    
    global void finish(Database.BatchableContext BC){}
    
    public static string setDynamicQueryObj(string sobjectApi,  set<Id> relatedRec){
        Set<String> SobjectFields = Schema.getGlobalDescribe().get(sobjectApi).getDescribe().fields.getMap().keySet();    
        List<String> fieldsInList = new List<String>(SobjectFields);
        string query ='SELECT ' + String.join(fieldsInList, ',') + ' FROM '+sobjectApi +' WHERE Id IN:relatedRec';
        system.debug(loggingLevel.ERROR, 'Interface query:'+query);
        return query;
    }
    
    public void sendInterface(Sobject recObj){
        string interfaceType=setInterfaceTypeByObj(recObj);
        string payload = getPayload(recObj).replaceAll('null', '""');
        system.debug(loggingLevel.ERROR, 'Interface Type:'+interfaceType+'\n payload:'+payload);
        InterfaceEndPoint__mdt EndPointURL = [SELECT EndPointURL__c,Interface__c FROM InterfaceEndPoint__mdt WHERE Interface__c=:interfaceType];
        Token__mdt[] tokens = [SELECT Token__c, CreatedAt__c, clientId__c, clientSecret__c, endpointForJson__c, endpointForToken__c 
                               FROM Token__mdt];
        
        HttpResponse response2 =preformHttpsRequest(tokens,payload,EndPointURL);
        String resPayload ='response status:'+response2.getStatus()+' status code:'+response2.getStatusCode()+'\n'+response2.getBody();
        resPayload=resPayload;
        system.debug(loggingLevel.ERROR, 'Interface Response:'+resPayload);
        setRecordsforUpdate(recObj,resPayload,payload,string.valueOf(response2.getStatusCode()));
    }
    
    private string setInterfaceTypeByObj(Sobject rec){
        string interfaceType='';
        SWITCH ON sobjectApi{
            WHEN 'Account'{
                interfaceType= 'Account';
            }
            WHEN 'TankStaging__c'{
                interfaceType= 'Tank';
            }
            WHEN 'Delivery_Note_Staging__c'{
                interfaceType='Invoice';
            }
            WHEN 'Order'{
                interfaceType= 'Order';
            }
            WHEN 'OrderStaging__c'{
                SWITCH ON  (String)rec.get('Interface_Type__c'){
                    WHEN '10'{
                        interfaceType= 'Account';
                    }
                    WHEN '20'{
                        interfaceType= 'Order';
                    }
                }
            }
        }
        return interfaceType;
    }
    
    private string getPayload(Sobject rec){
        string payload;
        SWITCH ON sobjectAPI{
            WHEN 'OrderStaging__c'{
                SWITCH ON  (String)rec.get('Interface_Type__c'){
                    WHEN '10'{
                        payload=(String)rec.get('CreditJSON__c');   
                    }
                    WHEN '20'{
                        string orderId=(String)rec.get('Order__c');
                        List< OrderStaging__c> recs= [SELECT Id,InterfaceStatus__c FROM OrderStaging__c WHERE Order__c=:orderId and InterfaceStatus__c='Success'];
                        payload=(String)rec.get('OrderJSON__c');
                        system.debug(loggingLevel.ERROR,'recs of succsses:'+recs.size());
                        if(recs.size()>0){
                            payload=payload.replace('"ActionType__c":"10"', '"ActionType__c":"20"');
                        }
                    }
                }
            }
            WHEN 'Order'{
                payload=(String)rec.get('OrderJSON__c');                    
            }
            WHEN 'TankStaging__c'{
                TankStaging__c tank= (TankStaging__c)rec;
                if(tank.googleInterface__c==true){
                    geocodeAddress(tank);
                    system.debug(loggingLevel.ERROR, 'google set Loacation:'+tank.TankJSON__c);
                }
                payload=tank.TankJSON__c;      
            }
            WHEN 'Delivery_Note_Staging__c'{
                payload=(String)rec.get('InvoiceJSON__c');   
            }
        }
        return payload;
    }
    
    private HttpResponse preformHttpsRequest(Token__mdt[] tokens, string payload,InterfaceEndPoint__mdt EndPointURLInfo){
        String applicationId        = null; // clientid
        String endpointForToken     = null; // SCPI token URL
        String secret               = null;
        String authorizationHeader  = null;
        system.debug(loggingLevel.error,'preformHttpsRequest URL:'+EndPointURLInfo.Interface__c);
      //   if(EndPointURLInfo.Interface__c!='Invoice'){
            applicationId = tokens[0].clientId__c; // clientid
            endpointForToken = tokens[0].endpointForToken__c; // SCPI token URL
            secret = tokens[0].clientSecret__c; // clientsecret
            authorizationHeader = 'Bearer ' + tokens[0].Token__c;
       //}
      /* else{
            applicationId = 'sb-dac2e50f-49a1-410c-bff8-49ab9b7e6609!b136791|it-rt-iclcpinonprod!b117912'; // clientid
            endpointForToken = 'https://iclcpinonprod.authentication.eu10.hana.ondemand.com/oauth/token'; // SCPI token URL
            secret = 'eb6de31c-8447-47d6-9324-c60e67f52b24$c_qa2ZZMNZSyq3jn2Yd1leoqu5cuovspz95PhJszEQk='; // clientsecret
       
            HttpRequest request = new HttpRequest();
            request.setMethod('POST');
            request.setEndpoint(endpointForToken);
            request.setBody('grant_type=client_credentials&client_id=' + applicationId + '&client_secret=' + secret);
            system.debug(logginglevel.ERROR, 'endpointForToken:'+endpointForToken+'  setBody:client_id:'+applicationId+' &client_secret=' + secret);  
            Http binding1 = new Http();
            HttpResponse response1 = binding1.send(request); // Sends the first request to get the token
            system.debug(logginglevel.ERROR, 'mimshakim response1:'+response1);            
            Map<String, Object> tokenResponse = (Map<String, Object>) JSON.deserializeUntyped(response1.getBody());
            String tokenAccess = (string) tokenResponse.get('access_token');
            authorizationHeader = 'Bearer ' + tokenAccess;
            system.debug(logginglevel.ERROR, 'mimshakim tokenAccess for Invoices:'+tokenAccess);
        }*/
      
        
        system.debug('token  authorizationHeader info: '+authorizationHeader);
        system.debug('payload:'+payload);
        system.debug('EndPointURL.EndPointURL__c:'+EndPointURLInfo.EndPointURL__c);
        
        
        HttpRequest sendJsonDataRequest = new HttpRequest();
        sendJsonDataRequest.setMethod('POST');
        sendJsonDataRequest.setHeader('Authorization', authorizationHeader);
        sendJsonDataRequest.setHeader('Content-Type', 'application/json');
        sendJsonDataRequest.setBody(payload);
        sendJsonDataRequest.setTimeout(60000);
        sendJsonDataRequest.setEndpoint(EndPointURLInfo.EndPointURL__c);
        
        Http binding2 = new Http();
        HttpResponse response2 = new HttpResponse();
        
        try{
            response2 = binding2.send(sendJsonDataRequest);
            system.debug('http request from url:'+EndPointURLInfo.EndPointURL__c+' response:'+response2.getBody());
            if(response2.getStatus()=='401'){
                HttpRequest request = new HttpRequest();
                request.setMethod('POST');
                request.setEndpoint(endpointForToken);
                request.setBody('grant_type=client_credentials&client_id=' + applicationId + '&client_secret=' + secret);
                system.debug(logginglevel.ERROR, 'endpointForToken:'+endpointForToken+'  setBody:client_id:'+applicationId+' &client_secret=' + secret);  
                Http binding1 = new Http();
                HttpResponse response1 = binding1.send(request); // Sends the first request to get the token
                system.debug(logginglevel.ERROR, 'mimshakim response1:'+response1);            
                Map<String, Object> tokenResponse = (Map<String, Object>) JSON.deserializeUntyped(response1.getBody());
                String tokenAccess = (string) tokenResponse.get('access_token');
                authorizationHeader = 'Bearer ' + tokenAccess;
                system.debug(logginglevel.ERROR, 'mimshakim tokenAccess for Invoices:'+tokenAccess);
                response2 = binding2.send(sendJsonDataRequest);
                system.debug('http request from url:'+EndPointURLInfo.EndPointURL__c+' response:'+response2.getBody());
            }
            
        }
        catch(CalloutException	e){
            response2.setBody('Error: callout error->'+e.getMessage());
            response2.setStatus('500');
        }
        return response2;
    }
    
    
    private void setRecordsforUpdate(Sobject rec,string resPayload,string payload, string StatusCode){
        SWITCH ON sobjectAPI{
            WHEN 'OrderStaging__c'{
                OrderStaging__c relatedRec= (OrderStaging__c)rec;
                relatedRec.InterfaceStatusCode__c=StatusCode;
                
                SWITCH ON  (String)rec.get('Interface_Type__c'){
                    WHEN '10'{
                        relatedRec.CreditResponse__c=resPayload;
                        OrderStagingUpdateCreditResponse.validateAccountApprovedSAP(relatedRec,orderItemsToUpdate);
                        system.debug(loggingLevel.ERROR, 'relatedRec.CreditResponse__c:'+resPayload);
                        system.debug(loggingLevel.ERROR, 'relatedRec.SAPCreditNotApproved__c:'+relatedRec.SAPCreditNotApproved__c);
                        system.debug(loggingLevel.ERROR, 'relatedRec.PurchaseOrder__c:'+relatedRec.PurchaseOrder__c);
                        relatedRec.PurchaseOrder__c=relatedRec.PurchaseOrder__c!=null?relatedRec.PurchaseOrder__c:'';
                        relatedRec.LastSentAction__c= relatedRec.LastSentAction__c!=null?relatedRec.LastSentAction__c+'\nCredit-sent on:'+system.now():'Credit-sent on:'+system.now();
                        if(resPayload!=null && resPayload!='' && relatedRec.OrderJSON__c!=null  ){
                            system.debug(loggingLevel.ERROR, 'relatedRec.relatedRec.OrderJSON__c:'+relatedRec.OrderJSON__c);
                            relatedRec.Interface_Type__c='20';
                            recsForUpdate.put(relatedRec.Id, relatedRec);
                            sendInterface(relatedRec);
                            existSuccses.put(relatedRec.Id, relatedRec);
                            
                        }
                        else{
                            relatedRec.InterfaceStatus__c='30';
                            recsForUpdate.put(relatedRec.Id, relatedRec);
                            existSuccses.put(relatedRec.Id, relatedRec);
                            
                        }
                    }
                    WHEN '20'{
                        relatedRec.InterfaceStatus__c=resPayload.contains('success')==true?'10':'20';
                        relatedRec.LastSentAction__c= relatedRec.LastSentAction__c!=null?relatedRec.LastSentAction__c+'\nHovalot-sent on:'+system.now():'Hovalot-sent on:'+system.now();
                        relatedRec.orderResponse__C =resPayload;
                        system.debug(loggingLevel.ERROR, 'resPayload order:'+relatedRec.InterfaceStatus__c+'---'+resPayload);
                        relatedRec.OrderJSON__c=payload;
                        recsForUpdate.put(relatedRec.Id, relatedRec);
                        existSuccses.put(relatedRec.Id, relatedRec);
                    }
                }
            }
            WHEN 'TankStaging__c'{
                TankStaging__c relatedRec= (TankStaging__c)rec;
                if(resPayload!=null){
                    relatedRec.InterfaceStatus__c=resPayload.contains('success')==true?'Success':'Failure';
                    relatedRec.TankResponse__c=resPayload.replaceAll('','');
                    relatedRec.TankResponse__c=relatedRec.TankResponse__c.replaceAll('"','');
                    if(relatedRec.TankResponse__c.contains('LocationIndex')){
                        relatedRec.TankResponse__c=relatedRec.TankResponse__c.substringBetween('LocationIndex', '}}').replaceAll('[^a-zA-Z0-9\\s+]','');
                        system.debug(loggingLevel.ERROR, 'resPayload tank:'+relatedRec.TankResponse__c);
                    }
                    updateRec.add(relatedRec);
                    recsForUpdate.put(relatedRec.Id, relatedRec);
                }
            }
            WHEN 'Delivery_Note_Staging__c'{
                Delivery_Note_Staging__c relatedDNS= (Delivery_Note_Staging__c)rec;
                DeliveryNote__c DN = [SELECT Id,Interface_Response__c,status__c FROM DeliveryNote__c WHERE Id=:relatedDNS.RelatedDeliveryNote__c];
                relatedDNS.InterfaceResponse__c=resPayload;
                updateRec.add(relatedDNS);
                recsForUpdate.put(relatedDNS.Id, relatedDNS);
                DN.Interface_Response__c=resPayload;
                DN.Status__c='70';
                updateRec.add(DN);
                recsForUpdate.put(DN.Id, DN);
                
                
            }
        }
    }
    
    private static  void geocodeAddress (TankStaging__c rec){
        Tank__c  relatedRec = [SELECT Id,Account__c,Account__r.BillingStreet, Account__r.BillingCity, Account__r.BillingState, Account__r.BillingCountry,
                               Account__r.BillingPostalCode 
                               FROM
                               Tank__c where Id=:rec.tank__C limit 1 ];
        Map<string,string> relatedCordinates = new  Map<string,string>();
        // Key for Google Maps Geocoding API
        String geocodingKey = 'AIzaSyBN60T8xWCJ1Xr2qdVOchs-yHWYvpR8ejg';
        // get the passed in address
        
        //check that we have enough information to geocode the address
        if((relatedRec.Account__r.BillingStreet == null) || (relatedRec.Account__r.BillingCity == null)) {
            System.debug(LoggingLevel.WARN,'Insufficient Data to Geocode Address');
        }
        //create a string for the address to pass to Google Geocoding API
        String geoAddress = '';
        if(relatedRec.Account__r.BillingStreet != null)
            geoAddress+=relatedRec.Account__r.BillingStreet + ', ';
        if(relatedRec.Account__r.BillingCity != null)
            geoAddress+= relatedRec.Account__r.BillingCity + ', ';
        if(relatedRec.Account__r.BillingState != null)
            geoAddress+= relatedRec.Account__r.BillingState + ', ';
        if(relatedRec.Account__r.BillingCountry != null)
            geoAddress+= relatedRec.Account__r.BillingCountry + ', ';
        if(relatedRec.Account__r.BillingPostalCode != null)
            geoAddress+= relatedRec.Account__r.BillingPostalCode;
        
        
        geoAddress= EncodingUtil.urlEncode(geoAddress, 'UTF-8');
        system.debug(loggingLevel.ERROR, 'geoAddress:'+geoAddress);
        
        //  build and make the callout to the Geocoding API
        Http  http = new Http();
        HttpRequest  request = new HttpRequest();
        request.setEndpoint('https://maps.googleapis.com/maps/api/geocode/json?address='
                            +
                            geoAddress + '&key=' + geocodingKey
                            + '&sensor=false');
        request.setMethod('GET');
        request.setTimeout(60000);
        try {
            // make the http callout
            HttpResponse response = http.send(request);
            system.debug(loggingLevel.ERROR, 'response:'+response.getBody());
            
            // parse JSON to extract co-ordinates
            JSONParser responseParser = JSON.createParser(response.getBody());
            
            //initialize co-ordinates
            double latitude = null;
            double longitude = null;
            while  (responseParser.nextToken() != null) {
                if ((responseParser.getCurrentToken() == JSONToken.FIELD_NAME) && (responseParser.getText() == 'location')) {
                    responseParser.nextToken();
                    while (responseParser.nextToken() != JSONToken.END_OBJECT) {
                        String locationText = responseParser.getText();
                        responseParser.nextToken();
                        if (locationText == 'lat'){
                            rec.TankJSON__c =rec.TankJSON__c.replace('"Location__Latitude__s":""','"Location__Latitude__s":"'+responseParser.getDoubleValue()+'"');
                            system.debug(loggingLevel.ERROR, 'latitude response:'+responseParser.getDoubleValue());
                        }
                        else if (locationText == 'lng'){
                            rec.TankJSON__c =rec.TankJSON__c.replace('"Location__Longitude__s":""','"Location__Longitude__s":"'+responseParser.getDoubleValue()+'"');
                            system.debug(loggingLevel.ERROR, 'longitude response:'+responseParser.getDoubleValue());
                        }
                        
                    }
                }
            }
        }
        catch(Exception e){
            system.debug(loggingLevel.ERROR, 'Callout Exception:'+e.getMessage());
        }
        
    }
}