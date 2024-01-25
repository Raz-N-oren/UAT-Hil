@isTest
public class TankInterfaceMock implements HttpCalloutMock {
	
    public HttpResponse respond( HttpRequest request ) {
        HttpResponse response = new HttpResponse();
        String jsonBody ='{"AddLocationToCustomerResult":"{\"StatusCode\":\"1\",\"Status\":\"success\",\"StatusDesc\":\"\",\"Data\":{\"LocationIndex\":28420}}"}';
        response.setBody(jsonBody);
        response.setStatusCode(200);
        return response;
    }

}