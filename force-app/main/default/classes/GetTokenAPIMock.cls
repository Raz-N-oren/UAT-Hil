@isTest
global class GetTokenAPIMock implements HttpCalloutMock {
    public HttpResponse respond( HttpRequest request ) {
        HttpResponse response = new HttpResponse();
        String jsonBody = '{'+
                '    "access_token": "MyTestToken"'+
                '}';
        response.setBody(jsonBody);
        response.setStatusCode(200);
        return response;
    }
}