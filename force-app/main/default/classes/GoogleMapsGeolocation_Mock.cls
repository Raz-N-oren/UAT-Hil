@isTest
public class GoogleMapsGeolocation_Mock implements HttpCalloutMock {
	
    public HttpResponse respond( HttpRequest request ) {
        HttpResponse response = new HttpResponse();
        String jsonBody ='{"results":[{"address_components":[{"long_name":"Talmei Yosef","short_name":"Talmei Yosef","types":["locality","political"]},{"long_name":"Beer Sheva","short_name":"Beer Sheva","types":["administrative_area_level_2","political"]},{"long_name":"South District","short_name":"South District","types":["administrative_area_level_1","political"]},{"long_name":"Israel","short_name":"IL","types":["country","political"]}],"formatted_address":"Talmei Yosef, Israel","geometry":{"bounds":{"northeast":{"lat":31.2064099,"lng":34.3701649},"southwest":{"lat":31.194818,"lng":34.354426}},"location":{"lat":31.199958,"lng":34.363751},"location_type":"APPROXIMATE","viewport":{"northeast":{"lat":31.2064099,"lng":34.3701649},"southwest":{"lat":31.194818,"lng":34.354426}}},"partial_match":true,"place_id":"ChIJ0V0XezKN_RQRl4SCp0EtT7s","types":["locality","political"]},{"address_components":[{"long_name":"Negev","short_name":"Negev","types":["establishment","natural_feature"]},{"long_name":"Beer Sheva","short_name":"Beer Sheva","types":["administrative_area_level_2","political"]},{"long_name":"South District","short_name":"South District","types":["administrative_area_level_1","political"]},{"long_name":"Israel","short_name":"IL","types":["country","political"]}],"formatted_address":"Negev","geometry":{"location":{"lat":30.7140861,"lng":34.8757476},"location_type":"APPROXIMATE","viewport":{"northeast":{"lat":30.7154350802915,"lng":34.87709658029149},"southwest":{"lat":30.7127371197085,"lng":34.87439861970849}}},"partial_match":true,"place_id":"ChIJSU26e6aKARURfWjMVrDpeDQ","types":["establishment","natural_feature"]}],"status":"OK"}';
        response.setBody(jsonBody);
        response.setStatusCode(200);
        return response;
    }

}