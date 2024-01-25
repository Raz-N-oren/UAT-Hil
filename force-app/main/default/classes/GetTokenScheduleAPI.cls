//////////////////////////////////////////////////////////////
/////  Code to activate the scheduled job once an houre  /////
///////////  should be run from anonymous window  ////////////
//////////////////////////////////////////////////////////////
/*
    String CRON_EXP = '0 0 * * * ?'; // sec, min, hour...
    GetTokenScheduleAPI sch = new GetTokenScheduleAPI(); 
    System.schedule('Get Token for Mimshakim', CRON_EXP, sch);
*/


global class GetTokenScheduleAPI implements Schedulable {
    global void execute(SchedulableContext ctx) {
        Token__mdt[] tokens = [
            SELECT Token__c, CreatedAt__c, clientId__c, clientSecret__c, endpointForJson__c, endpointForToken__c 
            FROM Token__mdt
        ];
        String applicationId = tokens[0].clientId__c; // clientid
        String endpointForToken = tokens[0].endpointForToken__c; // SCPI token URL
        String secret = tokens[0].clientSecret__c; // clientsecret

        getToken(endpointForToken, applicationId, secret);
    }

    @future(callout=true)
    private static void getToken(String endpointForToken, String applicationId, String secret){
        HttpRequest request = new HttpRequest();
        request.setMethod('POST');
        request.setEndpoint(endpointForToken);
        request.setBody('grant_type=client_credentials&client_id=' + applicationId + '&client_secret=' + secret);
        Http binding1 = new Http();
        HttpResponse response1 = binding1.send(request); // Sends the first request to get the token
        Map<String, Object> tokenResponse = (Map<String, Object>) JSON.deserializeUntyped(response1.getBody());
        String tokenAccess = (string) tokenResponse.get('access_token');

        saveTokenToMtd(tokenAccess, 'Mimshakim');
    }

    private static void saveTokenToMtd (String token, String label){
        Metadata.CustomMetadata customMetadata =  new Metadata.CustomMetadata();
        customMetadata.fullName = 'Token__mdt.' + label;
        customMetadata.label = label;

        /* Create the Object of CustomMetadataValue */
        Metadata.CustomMetadataValue tokenField = new Metadata.CustomMetadataValue();
        Metadata.CustomMetadataValue timeField = new Metadata.CustomMetadataValue();
        /* Provide the API Name of the Field like Admin__c */
        tokenField.field = 'Token__c';
        timeField.field = 'CreatedAt__c';
        /* Provide the value for the field */
        tokenField.value = token;
        timeField.value = datetime.now();
        /* Add this field to the Metadata That we created */ 
        customMetadata.values.add(tokenField);
        customMetadata.values.add(timeField);

        Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
        mdContainer.addMetadata(customMetadata);
        
        CreateUpdateMetadataUtils callback = new CreateUpdateMetadataUtils();
        // Id jobId = Metadata.Operations.enqueueDeployment(mdContainer, callback);
        // For test to work
        String jobId = Test.isRunningTest() ? 'Fake Job Id' : Metadata.Operations.enqueueDeployment(mdContainer, callback);
    }    
}